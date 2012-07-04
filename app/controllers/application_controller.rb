class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :force_www
  before_filter :allow_or_authorize

  def force_www
    if request.host == Env['BASE_DOMAIN']
      redirect_to :host => CONFIG.home_domain
    end
  end

  def allow_or_authorize
    if Env['AUTH_USER'].present? && Env['AUTH_PASS'].present?
      authorize unless logged_in?
    end
  end

  private

  def authorize
    session[:logged_in] = authenticate_or_request_with_http_basic do |username, password|
      username == Env['AUTH_USER'] && password == Env['AUTH_PASS']
    end
  end

  def logged_in?
    session[:logged_in] == true
  end

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def port
    request.port == 80 ? '' : ":#{request.port}"
  end

end
