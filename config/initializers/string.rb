require_relative "../../lib/gollum"
require_relative "../../lib/subdomains"

class String
  def strip_lines!
    lines = split( $/ )    # $/ is the current ruby line ending, \n by default
    lines.map!( &:strip )
    processed = lines.join( $/ )
    processed.strip!
    replace processed
  end

  def slug(type)
    case type
      when :page
        page_name_safe
      when :subdomain
        subdomain_safe
      when :padded_subdomain
        padded_subdomain_safe
      else
        raise ArgumentError, "Unknown slug type #{type.inspect}"
    end
  end

  def page_name_safe(char_white_sub = '-', char_other_sub = '-')
    Gollum::Page.cname(self, char_white_sub, char_other_sub)
  end

  def padded_subdomain_safe
    massaged = subdomain_safe
    if massaged.size < MINIMUM_SUBDOMAIN_LENGTH
      massaged << '-' unless massaged.empty?
      massaged << ( MINIMUM_SUBDOMAIN_LENGTH - massaged.size ).times.map{ (rand*10).floor.to_s }.join
    end
    massaged
  end

  def subdomain_safe
    gsub(/[^[[:alnum:]]-]/, '-').gsub(/^-+/, '')
  end

  def domain
    match = self.match(%r{^\s*https?://(?:www\.)?([^/]+)})
    (match && match[1]) ? match[1] : ''
  end

end
