require 'active_model'
defined?(require_dependency) ? require_dependency("stores/github_store") : require_relative("../../lib/stores/github_store")
require_relative "../../lib/stores/all"

class Page
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  attr_reader   :errors

  attr_accessor :title, :content, :username

  validates :title, :length => {:minimum => 8}

  def initialize(attributes = {})
    @attributes  = attributes
    @attributes.each do |name, value|
      send("#{name}=", value)
    end
    @errors = ActiveModel::Errors.new(self)
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
    self.class.put_markdown(Env['HOME_SLUG'], content, :collection => self.class.canonicalize(subdomain))
  end

  def slug
    #title.present? title.slug(:padded_subdomain) : Env['HOME_SLUG']
    Env['HOME_SLUG']
  end

  def subdomain
    "#{title.slug(:padded_subdomain)}.#{username.slug(:padded_subdomain)}"
  end

  def self.get_html(subdomain, slug)
    markdown2html get_markdown(subdomain, slug)
  end

  def self.get_markdown(subdomain, slug)
    slug = Env['HOME_SLUG'] if slug.empty?
    subdomain = canonicalize(subdomain)
    markdown = begin
      Store.get_text "#{slug}.markdown", :collection => subdomain
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
    record_update(slug, metadata)
  end

  def self.record_update(slug, metadata)
    updates = Store.get_struct('updates', :collection => 'meta') || []
    updates.delete_if{|page| page['collection'] == metadata[:collection] && page['slug'] == slug }
    updates.unshift({
        collection: metadata[:collection],
        slug: slug,
        updated: Time.now.utc.iso8601
      })
    updates.pop if updates.size > Env['MAX_UPDATES'].to_i
    Store.put_struct 'updates', updates, :collection => 'meta'
  end

  def self.origin_message(subdomain)
    original_domain = subdomain.split('.').first.gsub('-', '.')
    "This is a remixable version of open licensed content from #{original_domain}"
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
