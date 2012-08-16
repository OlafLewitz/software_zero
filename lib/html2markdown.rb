# encoding: utf-8
#
# This file originally from https://github.com/singpolyma/HTML2Markdown/blob/249a986ffd28188b9459a9c6e7fde423bf0748b6/html2markdown.rb
# This referenced original work is copyright © 2010, Stephen Paul Weber <singpolyma.net>:
# ===============
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# ===============
#
# README:
# This is just a small piece of ruby code that turns HTML into Markdown-compatible text.
#
# It is based on Nokogiri, and supports certain features of HTML5 (such as the effect sections have on headings).
#
# Example:
#
# 	HTML2Markdown.new('<h1>test</h1>').to_s
#

require 'nokogiri'
require 'uri'

class HTML2Markdown

  def initialize(str, baseurl=nil)
    @links = []
    @baseuri = (baseurl ? URI::parse(baseurl) : nil)
    @section_level = 0
    @encoding = str.encoding
    @markdown = output_for(Nokogiri::HTML(str, baseurl).root).gsub(/\n\n+/, "\n\n")
  end

  def to_s
    i = 0
    @markdown.to_s + "\n\n" + @links.map {|link|
      i += 1
      "[#{i}]: #{link[:href]}" + (link[:title] ? " (#{link[:title]})" : '')
    }.join("\n")
  end

  def output_for_children(node)
    node.children.map {|el|
      output_for(el)
    }.join
  end

  def add_link(link)
    if @baseuri
      begin
        link[:href] = URI::parse(link[:href])
      rescue Exception
        link[:href] = URI::parse('')
      end
      link[:href].scheme = @baseuri.scheme unless link[:href].scheme
      unless link[:href].opaque
        link[:href].host = @baseuri.host unless link[:href].host
        link[:href].path = @baseuri.path.to_s + '/' + link[:href].path.to_s if link[:href].path.to_s[0] != '/'
      end
      link[:href] = link[:href].to_s
    end
    @links.each_with_index {|l, i|
      if l[:href] == link[:href]
        return i+1
      end
    }
    @links << link
    @links.length
  end

  def wrap(str)
    return str if str =~ /\n/
    out = ''
    line = []
    str.split(/[ \t]+/).each {|word|
      line << word
      if line.join(' ').length >= 74
        out << line.join(' ') << " \n"
        line = []
      end
    }
    out << line.join(' ') + (str[-1..-1] =~ /[ \t\n]/ ? str[-1..-1] : '')
  end

  def output_for(node)
    case node.name
      when 'head', 'style', 'script'
        ''
      when 'br'
        "  \n"
      when 'p', 'div'
        "\n\n#{wrap(output_for_children(node))}\n\n"
      when 'section', 'article'
        @section_level += 1
        o = "\n\n----\n\n#{output_for_children(node)}\n\n"
        @section_level -= 1
        o
      when /h(\d+)/
        "\n\n" + ('#'*($1.to_i+@section_level) + ' ' + output_for_children(node)) + "\n\n"
      when 'blockquote'
        @section_level += 1
        o = ("\n\n> #{wrap(output_for_children(node)).gsub(/\n/, "\n> ")}\n\n").gsub(/> \n(> \n)+/, "> \n")
        @section_level -= 1
        o
      when 'ul'
        "\n\n" + node.children.map {|el|
          next if el.name == 'text'
          "* #{output_for_children(el).gsub(/^(\t)|(    )/, "\t\t").gsub(/^>/, "\t>")}\n"
        }.join + "\n\n"
      when 'ol'
        i = 0
        "\n\n" + node.children.map {|el|
          next if el.name == 'text'
          i += 1
          "#{i}. #{output_for_children(el).gsub(/^(\t)|(    )/, "\t\t").gsub(/^>/, "\t>")}\n"
        }.join + "\n\n"
      when 'pre', 'code'
        block = "\t" + wrap(output_for_children(node)).gsub(/\n/, "\n\t")
        if block.count("\n") < 1
          "`#{output_for_children(node)}`"
        else
          block
        end
      when 'hr'
        "\n\n----\n\n"
      when 'a', 'link'
        link = {:href => node['href'], :title => node['title']}
        "[#{output_for_children(node).gsub("\n",' ')}][#{add_link(link)}]"
      when 'img'
        link = {:href => node['src'], :title => node['title']}
        "![#{node['alt']}][#{add_link(link)}]"
      when 'video', 'audio', 'embed'
        link = {:href => node['src'], :title => node['title']}
        "[#{output_for_children(node).gsub("\n",' ')}][#{add_link(link)}]"
      when 'object'
        link = {:href => node['data'], :title => node['title']}
        "[#{output_for_children(node).gsub("\n",' ')}][#{add_link(link)}]"
      when 'i', 'em', 'u'
        "_#{output_for_children(node)}_"
      when 'b', 'strong'
        "**#{output_for_children(node)}**"
      # Tables are not part of Markdown, so we output WikiCreole
      when 'tr'
        node.children.select {|c|
          c.name == 'th' || c.name == 'td'
        }.map {|c|
          output_for(c)
        }.join.gsub(/\|\|/, '|') + "\n"
      when 'th', 'td'
        "|#{'=' if node.name == 'th'}#{output_for_children(node)}|"
      when 'text'
        # Sometimes Nokogiri lies. Force the encoding back to what we know it is
        if (c = node.content.force_encoding(@encoding)) =~ /\S/
          c.gsub!(/\n\n+/, '<$PreserveDouble$>')
          c.gsub!(/\s+/, ' ')
          c.gsub(/<\$PreserveDouble\$>/, "\n\n")
        else
          c
        end
      else
        wrap(output_for_children(node))
    end
  end

end