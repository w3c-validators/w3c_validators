require File.dirname(__FILE__) + '/test_helper'

# Test cases for the CssParser.
class MarkupValidatorTests < Test::Unit::TestCase
include W3CValidators
  def setup
    @v = MarkupValidator.new

    @valid_fragment = <<-EOV
      <div class="example">This is a test</div>
    EOV

    @invalid_fragment = <<-EOI
      <div class="example>This is a test
    EOI

  end

  def test_converting_boolean_params_to_integers
    return
  end

  def test_overriding_doctype
    doctype = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    @v.set_doctype!(doctype, false)
    r = @v.validate_uri('http://dunae.ca/', true)
    flunk
    assert_equal doctype, r.doctype
    return
  end

  def test_overriding_doctype_for_fallback_only
    doctype = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">'
    @v.set_doctype!(doctype, true)
    r = @v.validate_uri('http://dunae.ca/', true)
    assert_not_equal doctype, r.doctype
    return
  end
  
  def test_overriding_charset
    return
  end

  def test_validating_uri_with_head_request
    r = @v.validate_uri('http://dunae.ca/', true)
    assert_equal 11, r.errors.length
    assert_equal 0, r.warnings.length
  end

  def test_validating_uri_with_soap
    r = @v.validate_uri('http://dunae.ca/', false)
    assert_equal 11, r.errors.length
    assert_equal 0, r.warnings.length
  end

  def test_debugging_uri
    @v.set_debug!
    r = @v.validate_uri('http://dunae.ca/', false)
    assert r.debug_messages.length > 0
  end

  def test_validating_file_with_soap
    return
  end

  def test_validating_fragment_with_soap
    return
    r = @v.validate_fragment(@valid_fragment, false)
    puts @valid_fragment
    r.errors.each do |err|
      puts err.to_s
    end

    assert_equal 0, r.errors.length

  end
end
