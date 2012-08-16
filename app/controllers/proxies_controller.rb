class ProxiesController < ApplicationController

  def github
    json = Store.get_struct params[:path], :collection => canonical_subdomain
    if json
      render :json => Rails.env.development? ? JSON.pretty_generate(json) : json
    else
      not_found
    end
  end

end
