class ::Env
  class << self
    def [](key)
      value = ENV[key]
      case value
        when 'true'
          true
        when 'false'
          false
        else
          value
      end
    end
  end
end