require 'active_model'
require_dependency "stores/github_store"  # reload changes to this file in dev env
require_relative "../../lib/stores/all"

class Page
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :url, :username, :topic

  validates_presence_of :url
  validates_length_of :topic, :minimum => 8
  validates_length_of :username, :minimum => 8

  def initialize(attributes = {})
    @attributes  = attributes
    @attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end

  def inspect
    inspection = if @attributes
      @attributes.map{ |key, value| "#{key}: #{value}" }.join(", ")
    else
      "not initialized"
    end
    "#<#{self.class} #{inspection}>"
  end

  def self.get_html(subdomain, slug)
    markdown2html get_markdown(subdomain, slug)
  end

  def self.get_markdown(subdomain, slug)
    jekyll_markdown = get_jekyll_markdown subdomain, slug
    jekyll_markdown.sub(/\A\s*---\r?\n.*?\n---\r?\n\s*/m, '')   # remove jekyll (YAML) front matter
  end

  def self.put_markdown(slug, markdown, metadata)
    put_jekyll_markdown(slug, markdown, metadata)
  end

  private

  def self.get_jekyll_markdown(subdomain, slug)
    subdomain = canonicalize(subdomain)
    jekyll_markdown = begin
      Store.get_text "#{slug}.markdown", :subdomain => subdomain
    rescue SocketError, socket_error
      if Rails.env.development?
        "---\nlayout:default\n---\n\n# Sample page\n\n* Point 1\n* Point 2"   # sample text for dev mode offline work
      else
        raise socket_error
      end
    end
    jekyll_markdown
  end

  def self.put_jekyll_markdown(slug, markdown, metadata)
    jekyll_front_matter = {
      'layout' => 'default',
    }.to_yaml
    #}.merge(metadata).to_yaml

    jekyll_markdown = "#{jekyll_front_matter}---\n\n#{markdown}"

    Store.put_text "#{slug}.markdown", jekyll_markdown, metadata
  end

  def self.markdown2html(markdown)
    return nil if markdown.nil?
    redcarpet = Redcarpet::Markdown.new Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true
    html = redcarpet.render markdown
    html
  end

  def self.canonicalize(subdomain)
    segments = subdomain.split('.')
    segments.reject!{|segment| segment == Env['DOMAIN_CONNECTOR']}
    raise "Expected 2 subdomain segments, got #{segments.inspect}" unless segments.size == 2
    segments.join('.')
  end

end
