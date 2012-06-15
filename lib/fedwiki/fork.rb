require 'pismo'
require 'html_massage'
require 'rest_client'

require_relative 'random_id'
require_relative '../env'
require_relative '../core-ext/nil'
require_relative '../../config/initializers/string'

module FedWiki

  class NoKnownOpenLicense < RuntimeError ; end

  SUBDOMAIN_PATTERN = "[a-zA-Z0-9][a-zA-Z0-9-]{0,62}"  # Subdomain 'segments' are 1 - 63 characters.  Although technically lower case, URLs may come in as mixed case.

  OPEN_LICENSE_PATTERNS = %w[
    gnu.org/licenses
    creativecommons.org/licenses
  ]

  SFW_BASE_DOMAIN = Env['SFW_BASE_DOMAIN'] || raise("please set the environment variable SFW_BASE_DOMAIN")

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

      metadata = Pismo::Document.new(html) rescue nil  # pismo occasionally crashes, eg on invalid UTF8
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

      subdomain = [subject, connector, curator, connector].compact.map{|segment| segment.slug}.join('.')
      sfw_site = "#{subdomain}.#{Env['SFW_BASE_DOMAIN']}"
      sfw_action_url = "http://#{sfw_site}/page/#{slug}/action"

      #############

      title = extract_title(doc) || metadata.title
      keywords = metadata.keywords.map(&:first)

      sfw_page_data = {
        'title' => title,
        'keywords' => keywords,
        'license_links' => license_links,
        'story' => [],
      }

      # Two ways to check the last updated time, both unsatisfactory...
      # sfw_page_data.merge! 'updated_at' => page.headers['Last-Modified']
      # sfw_page_data.merge! 'updated_at' => meta.datetime.utc.iso8601 if meta.datetime rescue nil

      #ap sfw_page_data

      #############

      html = massage_html(html, url)
      html = remove_first_h1_if_same_as_title(html, title)
      html = convert_links_to_crawled_pages_to_wikilinks(html, origin_domain, options[:site_urls])
      html.strip_lines!
      html_chunks = html.split(/\n{2,}/)
      sep = [%{<hr />}]
      attribution_html = [%{This page was forked with permission from <a href="#{url}" target="_blank">#{url}</a>}]

      (html_chunks + sep + attribution_html + sep + license_links).each do |html_chunk|
        sfw_page_data['story'] << ({
          'type' => 'paragraph',
          'id' => RandomId.generate,
          'text' => html_chunk
        })
      end

      #############

      push_to_github :path => "#{slug}.json", :content => JSON.pretty_generate(sfw_page_data), :repo => 'test'

      #############

      begin
        sfw_do(sfw_action_url, :create, sfw_page_data)
      rescue RestClient::Conflict
        sfw_do(sfw_action_url, :update, sfw_page_data)
      end

      fork_url = "http://#{sfw_site}/view/#{slug}"
      fork_url
    end

    def massage_html(html, url)
      sanitize_options = HtmlMassage::DEFAULT_SANITIZE_OPTIONS.merge(
          :elements => %w[
            a img
            h1 h2 h3 hr
            table th tr td
            em strong b i
          ],
          :attributes => {
            :all => [],
            'a' => %w[ href ],
            'img' => %w[ src alt ],
          }
      )
      begin
        HtmlMassage.html html, :source_url => url, :links => :absolute, :images => :absolute, :sanitize => sanitize_options
      rescue Encoding::CompatibilityError
        return # TODO: manage this inside the html_massage gem!
      end
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
            link['class'] = "#{link['class']} fedwiki-internal".strip # the class is for later client-side processing
          end
        end
      end
      doc.to_html
    end

    def sfw_do(sfw_action_url, action, sfw_page_data)
      action_json = JSON.pretty_generate 'type' => action, 'item' => sfw_page_data
      #begin
      RestClient.put "#{sfw_action_url}", :action => action_json, :content_type => :json, :accept => :json
      #rescue RestClient::ResourceNotFound
      #  puts "!!! ERROR: SFW SERVER NOT FOUND at #{sfw_action_url}"
      #end
    end

    def push_to_github(params)
      repo = params[:repo]
      branch = github :get, repo, "refs/heads/master"
      last_commit_sha = branch['object']['sha']

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
                          :parents => [last_commit],
                          :tree => new_content_tree_sha,
                          :message => 'commit via api'
      new_commit_sha = new_commit['sha']

      # update branch to point to new commit
      # see http://developer.github.com/v3/git/refs/
      github :patch, repo, "/refs/heads/master",
             :sha => new_commit_sha
    end

    def github(method, repo, resource, params={})
      JSON.parse RestClient.send(method,
                                 "https://#{ENV['GITHUB_USER']}:#{ENV['GITHUB_PASS']}@api.github.com" +
                                   "/repos/#{ENV['GITHUB_USER']}/#{repo}/git/#{resource}",
                                 params.to_json, :content_type => :json, :accept => :json
                 )
    end

  end

end

