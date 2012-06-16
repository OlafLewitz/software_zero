require 'pismo'
require 'html_massage'
require 'rest_client'

require_relative '../env'
require_relative '../core-ext/nil'
require_relative '../../config/initializers/string'

module FedWiki

  class NoKnownOpenLicense < RuntimeError;
  end

  SUBDOMAIN_PATTERN = "[a-zA-Z0-9][a-zA-Z0-9-]{0,62}" # Subdomain 'segments' are 1 - 63 characters.  Although technically lower case, URLs may come in as mixed case.

  OPEN_LICENSE_PATTERNS = %w[
    gnu.org/licenses
    creativecommons.org/licenses
  ]

  class << self
    def open_site(data, options={})
      urls = data.keys
      data.each do |url, doc|
        sleep rand*4
        begin
          if fork_url = open(doc, url, options.merge(:site_urls => urls))
            puts "Created fedwiki page -->"
            puts
            puts fork_url
          end
        rescue FedWiki::NoKnownOpenLicense
          print "no known open license"
        end
      end
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
        (?:en\.)?
        (#{SUBDOMAIN_PATTERN})
        ((?:\.#{SUBDOMAIN_PATTERN})+)?
      }x).to_a

      url_chunks.shift # discard full regexp match
      origin_domain = url_chunks.join
      slug = url.slug


      origin = options[:shorten_origin_domain] ? url_chunks.first : url_chunks.join
      subject = options[:topic] || origin
      connector = options[:domain_connector]
      curator = options[:username] || Env['CURATOR']

      subdomain = [subject, connector, curator, connector].compact.map { |segment| segment.slug }.join('.')

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
      html = remove_first_h1_if_same_as_title(html, title)
      html = convert_links_to_crawled_pages_to_wikilinks(html, origin_domain, options[:site_urls])
      html.strip_lines!
      html.gsub!(/\n{3,}/, "\n\n")
      #html_chunks = html.split(/\n{2,}/)
      sep = [%{<hr />}]
      attribution_html = [%{This page was forked with permission from <a href="#{url}" target="_blank">#{url}</a>}]

      html += (sep + attribution_html + sep + license_links).join("\n\n")

      #############

      push_to_github :path => "#{slug}.html", :content => html, :repo => 'test'

      #############

      [ subdomain, slug ]
    end

    def massage_html(html, url)
      sanitize_options = HtmlMassage::DEFAULT_SANITIZE_OPTIONS.merge(
        :elements => %w[
            a img
            hr p
            h1 h2 h3 h4 h5 h6

            table tbody th tr td
            ul ol li
            dd dl dt

            b i em strong
            small strike
            sub sup

            blockquote
            code pre
          ],
        :attributes => {
          :all => [],
          'a' => %w[ href ],
          'img' => %w[ src alt ],
          'td' => %w[ colspan rowspan ],
        }
      )
      #HtmlMassage.html html, :source_url => url, :links => :absolute, :images => :absolute, :sanitize => sanitize_options
      HtmlMassage.text html, :source_url => url, :links => :absolute, :images => :absolute, :sanitize => sanitize_options
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
            link_slug = match['href_path'].slug
            link['href'] = link_slug
          end
        end
      end
      doc.to_html
    end

    def push_to_github(params)
      repo = params[:repo]

      # get the head of the master branch
      # see http://developer.github.com/v3/git/refs/
      branch = github(:get, repo, "refs/heads/master")
      last_commit_sha = branch['object']['sha']

      # create the last commit
      # see http://developer.github.com/v3/git/commits/
      last_commit = github :get, repo, "commits/#{last_commit_sha}"
      last_tree_sha = last_commit['tree']['sha']

      # create tree object (also implicitly creates a blob based on content)
      # see http://developer.github.com/v3/git/trees/
      new_content_tree = github :post, repo, :trees,
                                :base_tree => last_tree_sha,
                                :tree => [{:path => params[:path], :content => params[:content], :mode => '100644'}]
      new_content_tree_sha = new_content_tree['sha']

      # create commit
      # see http://developer.github.com/v3/git/commits/
      new_commit = github :post, repo, :commits,
                          :parents => [last_commit_sha],
                          :tree => new_content_tree_sha,
                          :message => 'commit via api'
      new_commit_sha = new_commit['sha']

      # update branch to point to new commit
      # see http://developer.github.com/v3/git/refs/
      github :patch, repo, "refs/heads/master",
             :sha => new_commit_sha
    end

    def github(method, repo, resource, params={})
      resource_url = "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@api.github.com" +
        "/repos/#{ENV['GITHUB_USER']}/#{repo}/git/#{resource}"
      if params.empty?
        JSON.parse RestClient.send(method, resource_url)
      else
        JSON.parse RestClient.send(method, resource_url, params.to_json, :content_type => :json, :accept => :json)
      end
    end
  end

end

