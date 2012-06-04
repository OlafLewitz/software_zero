class Env
  class << self
    def [](key)
      value = ENV[key]
      case value
        when 'false'
          false
        when 'true'
          false
        else
          value
      end
    end
  end
end