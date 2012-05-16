require File.expand_path('test_helper', File.dirname(__FILE__))

# Test cases for the CSSValidator.
class CSSValidatorTests < Test::Unit::TestCase
  include W3CValidators
  def setup
    @v = CSSValidator.new

    @invalid_fragment = <<-EOT
    a { color: white; }
    body { margin: blue; }
    
    EOT

    sleep 1
  end

  def test_vendor_extensions_as_errors
    @v.set_vendor_extension_warning!('Errors')
    r = @v.validate_text('some-class { -moz-border-radius: 3px; }')
    assert_errors r, 1
  end

  def test_vendor_extensions_as_warnings
    @v.set_vendor_extension_warning!('Warnings')
    r = @v.validate_text('some-class { -moz-border-radius: 3px; }')
    assert_no_errors r
    assert_warnings r, 1
  end

  def test_overriding_css_profile
    @v.set_profile!(:svgbasic)
    r = @v.validate_text(@invalid_fragment)
    assert_equal 'svgbasic', r.css_level
  end

  def test_validating_file
    file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/invalid_css.css')
    r = @v.validate_file(file_path)
    assert_errors r, 1
  end

  def test_validating_uri
    @v.set_profile!(:svgbasic)
    r = @v.validate_text(@invalid_fragment)
    assert_errors r, 1
  end
 
  def test_validating_text
    r = @v.validate_text(@invalid_fragment)
    assert_errors r, 1
  end

  def test_validating_text_via_file
    file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/invalid_css.css')
    fh = File.new(file_path, 'r+')    
    r = @v.validate_file(fh)
    fh.close
    assert_errors r, 1
  end

end
