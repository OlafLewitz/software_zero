class Store
  class << self

    attr_writer :app_root

    def set(store_classname, app_root)
      # @store_class is literally the class FileStore by default, or if a class name is passed in, another subclass of Store
      @store_class = store_classname ? Kernel.const_get(store_classname) : FileStore
      @store_class.app_root = app_root
      @store_class
    end

    def method_missing(*args)
      # For any method not implemented in *this* class, pass the method call through to the designated Store subclass
      @store_class.send(*args)
    end

    ### GET

    def get_struct(path, metadata={})
      json = get_text "#{path}.json", metadata
      JSON.parse json if json && !json.to_s.strip.empty?
    end

    ### PUT

    def put_struct(path, ruby_data, metadata={})
      json = JSON.pretty_generate(ruby_data)
      put_text "#{path}.json", json, metadata
      ruby_data
    end

  end

end
