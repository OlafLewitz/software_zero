class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :force_www

  def force_www
    if ENV['REDIRECT_TO_WWW'] && request.host !~ /^www\./
      redirect_to :host => "www.#{request.host}"
    end
  end

end
