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

  #unless Rails.application.config.consider_all_requests_local
    rescue_from ActionController::RoutingError, with: :render_404
  #end

  private

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def render_404(_)
    respond_to do |format|
      format.html { render file: Rails.root.join('public/404.html'), status: 404 }
      format.json { render json: {status: 404, message: "Not Found"}, status: 404 }
      format.all { render nothing: true, status: 404 }
    end
  end

  def authorize
    session[:logged_in] = authenticate_or_request_with_http_basic do |username, password|
      username == Env['AUTH_USER'] && password == Env['AUTH_PASS']
    end
  end

  def logged_in?
    session[:logged_in] == true
  end

  def canonical_subdomain
    subdomain = request.host.sub(/#{Regexp.escape(Env['BASE_DOMAIN'])}$/, '')   # This is "normally" the same as request.subdomain, but works for all TLDs, regardless of how many periods they contain
    Page.canonicalize(subdomain)
  end

end
