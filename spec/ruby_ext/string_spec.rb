# encoding: UTF-8
require_relative "../../config/initializers/string"

def section (comment)
  $section = comment
  $counter = 0
end

def test (given, expected)
  describe "#{$section}: Test ##{$counter+=1}" do
    it "should convert the string #{given.inspect} to the slug #{expected.inspect}" do
      given.slug(:page).should == expected
    end
  end
end

# the following test cases presume to be implementation language agnostic
# perhaps they should be included from a common file


section 'case and hyphens'
test 'Welcome Visitors', 'Welcome-Visitors'
test 'welcome visitors', 'welcome-visitors'
test 'Welcome-visitors', 'Welcome-visitors'

section 'numbers and punctuation'
test '2012 Report', '2012-Report'
test 'Ward\'s Wiki', 'Ward\'s-Wiki'
test 'ø\'malley', 'ø\'malley'
test 'holy cats !!! you don\'t say', 'holy-cats-!!!-you-don\'t-say'
test 'Pride & Prejudice', 'Pride-&-Prejudice'
test '---holy cats !!! ---------', '---holy-cats-!!!----------'

section 'white space'
test 'Welcome  Visitors', 'Welcome--Visitors'
test '  Welcome Visitors', '--Welcome-Visitors'
test 'Welcome Visitors  ', 'Welcome-Visitors--'

section 'foreign language'
test 'Les Misérables', 'Les-Misérables'
