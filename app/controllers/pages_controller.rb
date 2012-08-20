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
      redirect_to "#{request.protocol}#{@page.subdomain}.#{Env['BASE_DOMAIN']}#{request.port_string}/#{@page.slug}"
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
      render :new
    end
  end

  def edit
    @slug = params[:id]
    @markdown = Page.get_markdown canonical_subdomain, @slug
    not_found unless @markdown

    @editor = {
      escaped_name: @slug,
      page_name: @title,
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
    Page.put_markdown @slug, @markdown, :collection => canonical_subdomain
    redirect_to "/#{@slug}"
  end

  def show
    @collection ||= canonical_subdomain

    @page_id = params[:slug]
    @page_html = Page.get_html @collection, @page_id
    not_found unless @page_html

    repo_url     = "https://github.com/#{Env['GITHUB_USER']}/#{@collection}"
    @fork_this   = %{<a href="#{repo_url}">Fork this #{Env['COLLECTION_LABEL'].downcase}</a> on Github}.html_safe
    @zipball_url = "https://github.com/#{Env['GITHUB_USER']}/#{@collection}/zipball/master"
    @full_width = true
  end

  def via
    @collection = request.subdomain.gsub /\.via$/, ''
    @origin_message = origin_message @collection
    show
    render :show
  end

  private

  def origin_message domain
    Page.origin_message domain
  end

end
