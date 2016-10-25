require File.expand_path('test_helper', File.dirname(__FILE__))

# Test cases for the HTML5Validator.
class HTML5ValidatorTests < Test::Unit::TestCase
  include W3CValidators
  def setup
    @v = NuValidator.new
    sleep 1
  end

  def test_getting_request_data
    VCR.use_cassette('html5_getting_request_data') do
      r = @v.validate_uri('https://doc75.github.io/w3c_validators_tests/valid_html5.html')
      assert_equal :html5, r.doctype
      assert_equal 'https://doc75.github.io/w3c_validators_tests/valid_html5.html', r.uri
      assert_no_errors r
      assert_no_warnings r
      assert r.is_valid?
    end
  end

  def test_validating_uri
    VCR.use_cassette('html5_validating_uri') do
      r = @v.validate_uri('https://doc75.github.io/w3c_validators_tests/invalid_html5.html')
      assert_errors r, 2
      assert_no_warnings r
      assert !r.is_valid?
    end
  end

  def test_validating_file
    omit("Pending, broken")
    file = File.dirname(__FILE__) + '/fixtures/invalid_html5.html'
    r = @v.validate_file(file)
    assert_errors r, 1
  end

  def test_validating_text
    omit("Pending, broken")
    valid_fragment = <<-EOV
    <!DOCTYPE html>
    <html lang="en-ca">
      <head>
        <title>HTML 5 Example</title>
      </head>
      <body>
        <!-- should have one error (missing </section>) -->
        <p>This is a sample HTML 5 document.</p>
        <section>
        <h1>Example of paragraphs</h1>
        This is the <em>first</em> paragraph in this example.
        <p>This is the second.</p>
        <p>Test<br>test</p>
      </body>
    </html>
    EOV
    
    r = @v.validate_text(valid_fragment)
    assert_errors r, 1
  end

  #def test_validating_text_via_file
  #  fh = File.new(File.dirname(__FILE__) + '/fixtures/invalid_html5.html', 'r+')    
  #  r = @v.validate_file(fh)
  #  fh.close
  #  assert_equal 1, r.errors.length
  #end


end
