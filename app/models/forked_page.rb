class ForkedPage < Page
  attr_accessor :url
  validates_presence_of :url
end
