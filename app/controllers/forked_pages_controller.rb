require_dependency "../../config/initializers/string"
require_dependency 'fork_this/open'

class ForkedPagesController < ApplicationController
  def new
    attrs = CONFIG.form_pre_filled ? {
      :url => 'http://en.wikipedia.org/wiki/Technological_singularity',
    } : {}

    @forked_page = ForkedPage.new attrs
    populate_recent_changes
  end

  def create
    @forked_page = ForkedPage.new(params[:forked_page])
    (populate_recent_changes and render :new and return) unless @forked_page.valid?

    @forked_page.fetch!
    (populate_recent_changes and render :new and return) unless @forked_page.valid?

    begin
      domain, slug = ForkThis.open(@forked_page.doc, @forked_page.url,
                                     :domain_connector => Env['DOMAIN_CONNECTOR'],
                                     :shorten_origin_domain => Env['SHORTEN_ORIGIN_DOMAIN']
      )
      redirect_to "#{request.protocol}#{domain}#{request.port_string}/#{slug}"
    rescue ForkThis::NoKnownOpenLicense
      @forked_page.errors.add :url, %{Whoops! We couldn't find a <href="http://creativecommons.org/licenses/" target="_blank">Creative Commons license</a> on this page -- No action was taken}
                                                        # todo fix html link rendering in the error above

      populate_recent_changes and render :new and return
    end
  end

  def populate_recent_changes
    @recent_changes = Store.get_struct('updates', :collection => 'meta') || []
  end

end
