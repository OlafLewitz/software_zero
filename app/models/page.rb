require 'active_model'
require_dependency "stores/github_store"  # reload changes to this file in dev env
require_relative "../../lib/stores/all"

class Page
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :title, :content, :username

  validates_length_of :title, :minimum => 8
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

  def save
    self.class.put_markdown(Env['HOME_SLUG'], content, :subdomain => self.class.canonicalize(subdomain))
  end

  def slug
    title.slug
  end

  def subdomain
    "#{title.slug}.#{username.slug}"

    #subject = title.slug
    #curator = username.slug
    #connector = Env['DOMAIN_CONNECTOR']
    #[subject, connector, curator, connector].compact.join('.')
  end

  def self.get_html(subdomain, slug)
    markdown2html get_markdown(subdomain, slug)
  end

  def self.get_markdown(subdomain, slug)
    subdomain = canonicalize(subdomain)
    markdown = begin
      Store.get_text "#{slug}.markdown", :subdomain => subdomain
    rescue SocketError, socket_error
      if Rails.env.development?
        "# Sample page\n\n* Point 1\n* Point 2"   # sample text for dev mode offline work
      else
        raise socket_error
      end
    end
    markdown
  end

  def self.put_markdown(slug, markdown, metadata)
    Store.put_text "#{slug}.markdown", markdown, metadata
  end

  private

  def self.markdown2html(markdown)
    return nil if markdown.nil?
    redcarpet = Redcarpet::Markdown.new Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true
    html = redcarpet.render markdown
    html
  end

  def self.canonicalize(subdomain)
    segments = subdomain.split('.')
    segments.reject!{|segment| segment == Env['DOMAIN_CONNECTOR']}
    raise "Expected either 1 or 2 subdomain segments, got #{segments.inspect}" unless segments.size == 1 || segments.size == 2
    segments.join('.')
  end

end
