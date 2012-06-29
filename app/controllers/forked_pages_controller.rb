require_dependency 'fork_this/open'

class ForkedPagesController < ApplicationController
  def new
    attrs = CONFIG.form_pre_filled ? {
      :url => 'http://en.wikipedia.org/wiki/Technological_singularity',
      :username => 'John Q. Public',
      :title => 'test only',
    } : {}

    @forked_page = ForkedPage.new attrs
  end

  def create
    @forked_page = ForkedPage.new(params[:forked_page])
    (render :new and return) unless @forked_page.valid?

    html = RestClient.get @forked_page.url
    doc = Nokogiri::HTML(html)
    begin
      subdomain, slug = ForkThis.open(doc, @forked_page.url,
                                     :username => @forked_page.username,
                                     :topic => @forked_page.title,
                                     :domain_connector => Env['DOMAIN_CONNECTOR'],
                                     :shorten_origin_domain => Env['SHORTEN_ORIGIN_DOMAIN']
      )
      redirect_to "#{request.protocol}#{subdomain}.#{Env['BASE_DOMAIN']}#{port}/#{slug}"
    rescue ForkThis::NoKnownOpenLicense
      @forked_page.errors.add :url, %{Whoops! We couldn't find a <href="http://creativecommons.org/licenses/" target="_blank">Creative Commons license</a> on this page -- No action was taken}
                                                        # todo fix html link rendering in the error above
      render :new
    end
  end

end
