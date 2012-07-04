class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :basic_auth
  before_filter :force_www

  def force_www
    if request.host == Env['BASE_DOMAIN']
      redirect_to :host => CONFIG.home_domain
    end
  end

  def basic_auth
    if Env['AUTH_USER'].present? && Env['AUTH_PASS'].present?
      authenticate_or_request_with_http_basic do |username, password|
        username == Env['AUTH_USER'] && password == Env['AUTH_PASS']
      end
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
