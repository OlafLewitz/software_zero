require 'pismo'
require 'rest_client'
require 'html_massage'

require_relative '../env'
require_relative '../core-ext/nil'
require_relative '../../config/initializers/string'
require_relative '../../lib/subdomains'
require File.dirname(__FILE__) + '/../../lib/html2markdown'

module ForkThis

  class NoKnownOpenLicense < RuntimeError;
  end

  OPEN_LICENSE_PATTERNS = %w[
    gnu.org/licenses
    creativecommons.org/licenses
  ]

  class << self

    def open_site(data, options={})
      pages = {}
      urls = data.keys
      data.each do |url, doc|
        sleep rand*4
        begin
          full_domain, slug, metadata = open(doc, url, options.merge(:site_urls => urls))
          if full_domain && slug
            puts "Created page -->"
            puts
            puts "#{full_domain}/#{slug}"
            pages[slug] = metadata
          end
        rescue ForkThis::NoKnownOpenLicense
          print "no known open license"
        end
      end
      pages
    end

    def open(doc, url, options={})
      puts
      print "    ... Trying #{url} ... "

      return if doc.nil?

      license_links = open_license_links(doc)
      raise NoKnownOpenLicense if license_links.empty?

      html = doc.to_s

      metadata = Pismo::Document.new(html) rescue nil # pismo occasionally crashes, eg on invalid UTF8
                                                      # for a list of metadata properties, see https://github.com/peterc/pismo
                                                      # To limit keywords to specific items we care about, consider this doc fragment --
                                                      #   New! The keywords method accepts optional arguments. These are the current defaults:
                                                      #   :stem_at => 20, :word_length_limit => 15, :limit => 20, :remove_stopwords => true, :minimum_score => 2
                                                      #   You can also pass an array to keywords with :hints => arr if you want only words of your choosing to be found.

      return if html.empty? || !metadata || url =~ /%23/ # whats up with %23?

      #############

      url_chunks = url.match(%r{
        ^
        https?://
        (?:www\.)?
        (#{DOMAIN_SEGMENT_PATTERN})
        ((?:\.#{DOMAIN_SEGMENT_PATTERN})+)?
        (/.*|)
        $
      }x).to_a

      url_chunks.shift # discard full regexp match
      name = url_chunks.pop
      origin_domain = url_chunks.join

      name.gsub!(/#.*$/, '')                     # strip off anchor tags, eg #section-2
      #name.gsub!(/\?.*$/, '')                    # strip off query sting, eg ?cid=6a0
      name.gsub!(/\.[[:alnum:]]{3,10}$/, '')     # strip off file extensions, eg .html
      name.gsub!(%r{^/|/$}, '')                  # strip off leading or trailing slash
      name = Env['HOME_SLUG'] if name.empty?
      name = name.slug(:page)

      origin = options[:shorten_origin_domain] ? url_chunks.first : url_chunks.join
      subject = options[:topic] ? options[:topic].slug(:padded_subdomain) : origin
      connector = options[:domain_connector]
      curator = options[:username]

      curator = curator.slug(:padded_subdomain) if curator

      subdomain           = [subject, connector, curator].compact.join('.')
      canonical_subdomain = [subject,            curator].compact.join('.')

      #############

      title = extract_title(doc) || metadata.title
      keywords = metadata.keywords.map(&:first)

      # TODO: feed this data into page metadata -- markdown yaml front matter and/or html meta tags?
      #sfw_page_data = {
      #  'title' => title,
      #  'keywords' => keywords,
      #  'license_links' => license_links,
      #  'story' => [],
      #}

      #############

      html = massage_html(html, url)
      html = convert_links_to_crawled_pages_to_wikilinks(html, origin_domain, options[:site_urls])
      #html.strip_lines!
      #html.gsub!(/\n{3,}/, "\n\n")

      html += %~

      <hr />

      This page was forked with permission from <a href="#{url}" target="_blank">#{url}</a>

      <hr />

      #{license_links.join("\n\n")}

      ~.strip_lines!

      markdown = html2markdown(html)
      word_count = markdown.split(/[^[[:alnum:]]]+/).size

      begin
        Page.put_markdown name, markdown, :collection => canonical_subdomain
        sleep (1 + rand)  # be nice to github
        full_domain = "#{subdomain}.#{Env['BASE_DOMAIN']}"
        [ full_domain, name, {size: word_count} ]
      rescue Faraday::Error::TimeoutError
        nil
      end

    end

    def html2markdown(html)
      markdown = HTML2Markdown.new(html).to_s
      #markdown = Remark.new(html, :reference_links => false).to_markdown
      markdown
    end

    def massage_html(html, url)
      HtmlMassage.html html,
                       :source_url => url,
                       :links => :absolute,
                       :images => :absolute,
                       :exclude => HtmlMassage::DEFAULT_EXCLUDE_OPTIONS + [
                          # Posterous blog
                          'div.editbox',
                          'div.postmeta',
                          'div.tag-listing',
                          'div.posterous_tweet_button',
                          'div.comment-count',
                          'div.col#secondary',

                        ]
    end

    def open_license_links(doc)
      links = license_links(doc, 'a[rel="license"]')
      !links.empty? ? links : license_links(doc, 'a')
    end

    def license_links(doc, selector)
      links = doc.css(selector).map do |license_link|
        OPEN_LICENSE_PATTERNS.map do |pattern|
          license_link.to_s if license_link['href'].to_s.match(Regexp.new pattern)
        end
      end
      links.flatten.compact
    end

    def extract_title(doc)
      %w[ h1 title .title ].each do |selector|
        if ( title_elements = doc.search( selector ) ).length == 1
          title = massage_title(title_elements.first.content)
          return title unless title.empty?
        end
      end
      nil
    end

    def massage_title(title)
      title.split( /\s+(-|\|)/ ).first.to_s.strip
    end

    def remove_first_h1_if_same_as_title(html, title)
      doc = Nokogiri::HTML.fragment(html)
      if (h1 = (doc / :h1).first) && massage_title(h1.content) == massage_title(title)
        h1.remove
      end
      doc.to_s
    end

    def convert_links_to_crawled_pages_to_wikilinks(html, origin_domain, site_urls)
      return html if site_urls.empty?
      doc = Nokogiri::HTML.fragment(html)
      links = doc / 'a'
      links.each do |link|
        if match = link['href'].to_s.match(%r[^.+?#{origin_domain}(?::\d+)?(?<href_path>/.*)$])
          if site_urls.include?(match[0])
            link_slug = match['href_path'].slug(:page)
            link['href'] = link_slug
          end
        end
      end
      doc.to_html
    end

  end

end

