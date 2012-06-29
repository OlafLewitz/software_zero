class PagesController < ApplicationController
  def new
    @markdown = Page.get_markdown 'meta', 'page_template'
    @editor = {
      content: @markdown,
      collection_label: Env['COLLECTION_LABEL'],
      footer: false,
      sidebar: false,
      is_create_page: true,
      is_edit_page: false,
      format: 'markdown'
    }
  end

  def create
    @page = Page.new(
      :title => params[:page],
      :content => params[:content],
      :username => params[:username]
    )

    if @page.valid?
      @page.save
      redirect_to "#{request.protocol}#{@page.subdomain}.#{Env['BASE_DOMAIN']}#{port}/#{@page.slug}"
    else
      @editor = {
        content: @page.content,
        page_name: @page.title,
        username: @page.username,
        collection_label: Env['COLLECTION_LABEL'],
        footer: false,
        sidebar: false,
        is_create_page: true,
        is_edit_page: false,
        format: 'markdown',
        errors_on_title_present: @page.errors[:title].present?,
        errors_on_title: @page.errors[:title].to_sentence,
        errors_on_username_present: @page.errors[:username].present?,
        errors_on_username: @page.errors[:username].to_sentence,
      }
      p 777, @page.errors.to_a
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
