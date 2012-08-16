require_dependency("stores/github_store")

class CollectionsController < ApplicationController

  def index
    collections_yaml = Store.get_text "collections.yml", :repo => 'meta'
    if collections_yaml
      @collections = YAML.load collections_yaml
    else
      @viz = :network
      @json_path = "/proxy/github/meta/linked_sites_d3_viz_format.json"
      @base_domain_with_connector_and_port = [Env['DOMAIN_CONNECTOR'], Env['BASE_DOMAIN']].compact.join('.') + request.port_string
      render :network
    end
  end

end
