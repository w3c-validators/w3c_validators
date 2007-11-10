require File.dirname(__FILE__) + '/test_helper'

# Test cases for the CSSValidator.
class CSSValidatorTests < Test::Unit::TestCase
  include W3CValidators
  def setup
    @v = CSSValidator.new

    @invalid_fragment = <<-EOT
    a { color: white; }
    body { margin: blue; }
    
    EOT

    #sleep 1
  end

  def test_overriding_css_profile
    @v.set_profile!(:svgbasic)
    r = @v.validate_text(@invalid_fragment)
    assert_equal 'svgbasic', r.css_level
  end

  def test_validating_file
    file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/invalid_css.css')
    r = @v.validate_file(file_path)
    assert_equal 1, r.errors.length
  end

  def test_validating_uri_with_soap
    @v.set_profile!(:svgbasic)
    r = @v.validate_text(@invalid_fragment)
    assert_equal 1, r.errors.length
  end
 
  def test_validating_text
    r = @v.validate_text(@invalid_fragment)
    assert_equal 1, r.errors.length
  end

 
end
