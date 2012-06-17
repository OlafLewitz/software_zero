class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :force_www

  def force_www
    if request.host == Env['BASE_DOMAIN']
      redirect_to :host => "www.#{request.host}"
    end
  end

end
