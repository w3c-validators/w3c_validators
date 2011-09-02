require File.expand_path('test_helper', File.dirname(__FILE__))
require 'ruby-debug'

# Test cases for the MarkupValidator.
class MarkupValidatorTests < Test::Unit::TestCase
  include W3CValidators
  def setup
    @v = MarkupValidator.new
    sleep 1
  end

  def test_overriding_doctype
    @v.set_doctype!(:html32, false)
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_equal '-//W3C//DTD HTML 3.2 Final//EN', r.doctype
  end

  def test_overriding_doctype_for_fallback_only
    @v.set_doctype!(:html32, true)
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_not_equal '-//W3C//DTD HTML 3.2 Final//EN', r.doctype
  end

  def test_overriding_charset
    @v.set_charset!(:utf_16, false)
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_equal 'utf-16', r.charset
  end

  def test_overriding_charset_for_fallback_only
    @v.set_doctype!(:utf_16, true)
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_not_equal 'utf-16', r.charset
  end

  def test_validating_uri_with_head_request
    r = @v.validate_uri_quickly('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_errors r, 1
  end

  def test_validating_uri_with_soap
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert_errors r, 1
    assert_no_warnings r
  end

  def test_debugging_uri
    @v.set_debug!
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')
    assert r.debug_messages.length > 0
  end

  def test_validating_file
    file = File.dirname(__FILE__) + '/fixtures/invalid_markup.html'
    r = @v.validate_file(file)
    assert_errors r, 1
    
    assert r.uri =~ /fixtures\/invalid_markup\.html$/
  end

  def test_validating_text
    skip("Pending, broken")
    valid_fragment = <<-EOV
      <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
      <title>Test</title>
      <body>
      <div class="example">This is a test</div>
      </body>
    EOV
    
    r = @v.validate_text(valid_fragment)
    assert_no_errors r
    assert_no_warnings r
  end

  def test_validating_text_via_file
    fh = File.new(File.dirname(__FILE__) + '/fixtures/invalid_markup.html', 'r+')    
    r = @v.validate_file(fh)
    fh.close
    assert_errors r, 1
  end


  def test_validator_abort
    @v.set_debug!
    assert_nothing_raised do
      r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_encoding.html')
      assert !r.is_valid?
      assert_errors r, 1
      assert_no_warnings r
    end
  end

  def test_validator_contains_details_of_error_conditions    
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_markup.html')    
    assert_not_nil r.errors[0].col
    assert_not_nil r.errors[0].line
    assert_not_nil r.errors[0].message
  end
end
