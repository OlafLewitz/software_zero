class String
  def strip_lines!
    lines = split( $/ )    # $/ is the current ruby line ending, \n by default
    lines.map!( &:strip )
    processed = lines.join( $/ )
    processed.strip!
    replace( processed )
  end

  def slug(options = {})
    massaged = self.dup

    # Massage path-like segments

    if %r{^https?://.+?(?<path>/.*|)$} =~ massaged
      massaged = path.to_s                           # discard protocol, domain, port -- just use path
      massaged = massaged.split('/').reject{|segment| segment.empty?}.last.to_s  # just the last path segment
      massaged.gsub!(/#.*$/, '')                     # strip off anchor tags, eg #section-2
      massaged.gsub!(/\?.*$/, '')                    # strip off query sting, eg ?cid=6a0
      massaged.gsub!(/\.[[:alnum:]]{3,10}$/, '')     # strip off file extensions, eg .html

      home_slug = options['home_slug'] || 'home'
      massaged = home_slug if massaged.empty?
    end

    # Remove single quotes within words, eg O'Malley -> OMalley, or Don't -> Dont

    massaged.gsub!(/(?<=[[:alpha:]])'(?=[[:alpha:]])/, '')

    # Replace unsupported chars with 'sep'

    sep = options[:sep] || '-'
    massaged.downcase!
    massaged.gsub!(/[^[[:alnum:]]-]+/, sep)
    unless sep.nil? || sep.empty?
      re_sep = Regexp.escape(sep)
      # No more than one of the separator in a row.
      massaged.gsub!(/#{re_sep}{2,}/, sep)
      # Remove leading/trailing separator.
      massaged.gsub!(/^#{re_sep}|#{re_sep}$/, '')
    end

    #print "\n        orig -> #{self}"
    #print "\n        slug -> #{massaged}"
    massaged
  end

  def domain
    match = self.match(%r{^\s*https?://(?:www\.)?([^/]+)})
    (match && match[1]) ? match[1] : ''
  end

end
