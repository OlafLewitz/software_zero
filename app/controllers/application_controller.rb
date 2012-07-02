class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :force_www

  def force_www
    if request.host == Env['BASE_DOMAIN']
      redirect_to :host => CONFIG.home_domain
    end
  end

  private

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def port
    request.port == 80 ? '' : ":#{request.port}"
  end

end
