require 'active_model'
require_dependency "stores/github_store"  # reload changes to this file in dev env

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

  def self.html(subdomain, slug)
    segments = subdomain.split('.')
    segments.reject!{|segment| segment == Env['DOMAIN_CONNECTOR']}
    raise "Expected 2 subdomain segments, got #{segments.inspect}" unless segments.size == 2
    canonical_subdomain = segments.join('.')
    markdown = Store.get_text "#{slug}.markdown", :subdomain => canonical_subdomain
    markdown2html(markdown)
  end

  private

  def self.markdown2html(markdown)
    redcarpet = Redcarpet::Markdown.new Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true
    html = redcarpet.render markdown
    html
  end

end
