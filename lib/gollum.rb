module Gollum
  class Page
    def self.cname(name, char_white_sub = '-', char_other_sub = '-')
      name.respond_to?(:gsub) ?
        name.gsub(%r{\s}, char_white_sub).gsub(%r{[/<>+]}, char_other_sub) :
        ''
    end
  end
end

