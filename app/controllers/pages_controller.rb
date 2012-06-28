require_dependency 'fork_this/open'

class PagesController < ApplicationController
  def new
    page_attrs = CONFIG.form_pre_filled ? {
      :url => 'http://en.wikipedia.org/wiki/Technological_singularity',
      :username => 'John Q. Public',
      :topic => 'Singularity',
    } : {}

    @page = Page.new page_attrs
  end

  def create
    @page = Page.new(params[:page])
    (render :new and return) unless @page.valid?

    html = RestClient.get @page.url
    doc = Nokogiri::HTML(html)
    begin
      subdomain, slug = ForkThis.open(doc, @page.url,
                                     :username => @page.username,
                                     :topic => @page.topic,
                                     :domain_connector => Env['DOMAIN_CONNECTOR'],
                                     :shorten_origin_domain => Env['SHORTEN_ORIGIN_DOMAIN']
      )
      port = request.port == 80 ? '' : ":#{request.port}"
      redirect_to "#{request.protocol}#{subdomain}.#{Env['BASE_DOMAIN']}#{port}/#{slug}"
    rescue ForkThis::NoKnownOpenLicense
      @page.errors.add :url, %{Whoops! We couldn't find a <href="http://creativecommons.org/licenses/" target="_blank">Creative Commons license</a> on this page -- No action was taken}
                                                        # todo fix html link rendering in the error above
      render :new
    end
  end

  def edit
    @slug = params[:id]
    @title = @slug.gsub('-', ' ')
    @markdown = Page.get_markdown canonical_subdomain, @slug
    not_found unless @markdown

    @editor = {
      escaped_name: @slug,
      page_name: @slug.gsub('-', ' '),
      page_path: "/pages/#{@slug}",
      content: @markdown,
      footer: false,
      sidebar: false,
      is_create_page: false,
      is_edit_page: true,
      format: 'markdown'
    }
  end

  def update
    @slug = params[:id]
    @markdown = params[:content]
    Page.put_markdown @slug, @markdown, :subdomain => canonical_subdomain
    redirect_to "/#{@slug}"
  end

  def show
    @canonical_subdomain = canonical_subdomain
    @page_id = params[:slug]
    @page_html = Page.get_html @canonical_subdomain, @page_id
    not_found unless @page_html
    @zipball_url = "https://github.com/#{Env['GITHUB_USER']}/#{@canonical_subdomain}/zipball/master"
    @git_clone_url = "git://github.com/#{Env['GITHUB_USER']}/#{@canonical_subdomain}.git"  # read-only clone URL
  end

  private

  def canonical_subdomain
    subdomain = request.host.sub(/#{Regexp.escape(Env['BASE_DOMAIN'])}$/, '')   # This is "normally" the same as request.subdomain, but works for all TLDs, regardless of how many periods they contain
    Page.canonicalize(subdomain)
  end

end



#get '/curators' do
#  @viz = :curators
#  @json_path = "http://sfw.#{Env['BASE_DOMAIN']}/viz/#{@viz}.json"
#  haml @viz
#
#  # Code formerly in SFW around splitting out curators and collections:
#  #
#  #
#  #set :minimum_subdomain_length, 8   # This is our application logic
#  #set :maximum_subdomain_length, 63  # This is a hard limit set by internet standards
#  #set :subdomain_pattern, "[a-z0-9][a-z0-9-]{#{settings.minimum_subdomain_length-1},#{settings.maximum_subdomain_length-1}}"
#  #set :curator_subdomain_pattern,             "(#{settings.subdomain_pattern})"
#  #set :curator_collection_subdomain_pattern,  "(#{settings.subdomain_pattern})\\.(#{settings.subdomain_pattern})"
#  #
#  #
#  #curators_hashes = []
#  #curators = {"name" => "", "children" => curators_hashes}
#  #
#  #for each page obj:
#  #  next unless page['site'] && page['site'].match(/^#{settings.curator_collection_subdomain_pattern}\./)
#  #
#  #  collection_subdomain, curator_subdomain = $1, $2
#  #
#  #  curator_hash = curators_hashes.find{ |curator_hash| curator_hash['name'] == curator_subdomain }
#  #  unless curator_hash
#  #    curator_hash = {"name" => curator_subdomain, "children" => []}
#  #    curators_hashes << curator_hash
#  #  end
#
#end

