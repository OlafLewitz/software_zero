require_dependency "../../config/initializers/string"
class ForkedPage < Page

  attr_accessor :url
  validates :url, :format => { :with => %r{
        \A
        https?://
        #{DOMAIN_SEGMENT_PATTERN}
        ((\.#{DOMAIN_SEGMENT_PATTERN})+)
        }x, :message => "this doesn't look like a web page address" }
  validate :no_error_from_last_connection_attempt

  def initialize(attributes = {})
    attributes[:url] = "http://#{attributes[:url]}" if attributes[:url].present? && attributes[:url] !~ %r{^https?://}
    attributes[:title] = attributes[:url].domain if attributes[:url].present?
    super attributes
    @error_message_from_last_connection_attempt = nil
  end

  def fetch!
    begin
      self.content = RestClient.get url
      @error_message_from_last_connection_attempt = nil
    rescue  RestClient::Exception => e
      @error_message_from_last_connection_attempt = RestClient::STATUSES[e.http_code]
    end
  end

  def doc
    Nokogiri::HTML(content)
  end

  def no_error_from_last_connection_attempt
    self.errors.add(:url, @error_message_from_last_connection_attempt) if @error_message_from_last_connection_attempt
  end

end
