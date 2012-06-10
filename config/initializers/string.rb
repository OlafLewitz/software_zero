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
      massaged.gsub!(/#.*$/, '')                     # strip off anchor tags, eg #section-2
      massaged.gsub!(/\?.*$/, '')                    # strip off query sting, eg ?cid=6a0
      massaged.gsub!(/\.[[:alnum:]]{3,10}$/, '')     # strip off file extensions, eg .html

      massaged.gsub! %r[^/wiki], ''
      massaged.gsub! %r[
        /\d{4}/\d{2}           # optional leading date stamp, eg /2012/12/great-post    or /blog/2012/12/great-post
        (?:/\d{2})?            #                              or /2012/12/21/           or /blog/brian/2012/12/21/great-post
        (?=/.*?[[:alpha:]])    # require at least one alpha char after the date (for the slug)
      ]x, ''


      home_slug = options['home_slug'] || 'home'
      massaged = home_slug if massaged.match(%r{^/?$})
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

end
