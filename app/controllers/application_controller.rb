class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :force_www

  def force_www
    if ENV['APP_SUBDOMAIN'] == 'www' && request.host !~ /^www\./
      redirect_to :host => "www.#{request.host}"
    end
  end

end
