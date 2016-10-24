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

  def test_overriding_css_profile
    VCR.use_cassette('css_overriding_css_profile') do
      @v.set_profile!(:css21)
      r = @v.validate_text(@invalid_fragment)
      assert_equal 'css21', r.css_level
    end
  end

  def test_validating_file
    VCR.use_cassette('css_validating_file') do
      file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/invalid_css.css')
      r = @v.validate_file(file_path)
      assert_errors r, 1
    end
  end

  def test_validating_uri
    VCR.use_cassette('css_validating_uri') do
      @v.set_profile!(:svgbasic)
      r = @v.validate_text(@invalid_fragment)
      assert_errors r, 1
    end
  end

  def test_validating_text
    VCR.use_cassette('css_validating_text') do
      r = @v.validate_text(@invalid_fragment)
      assert_errors r, 1
    end
  end

  def test_validating_text_via_file
    VCR.use_cassette('css_validating_text_via_file') do
      file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/invalid_css.css')
      fh = File.new(file_path, 'r+')
      r = @v.validate_file(fh)
      fh.close
      assert_errors r, 1
    end
  end
end
