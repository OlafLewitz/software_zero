class CollectionsController < ApplicationController

  def index
    collections_yaml = Store.get_text "collections.yml", :repo => 'meta'
    raise 'No collections.yml found' unless collections_yaml
    @collections = YAML.load collections_yaml
  end

end
