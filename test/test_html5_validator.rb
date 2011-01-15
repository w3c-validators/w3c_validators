require File.expand_path('test_helper', File.dirname(__FILE__))

# Test cases for the HTML5Validator.
class HTML5ValidatorTests < Test::Unit::TestCase
  include W3CValidators
  def setup
    @v = NuValidator.new
    sleep 1
  end

  def test_getting_request_data
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/valid_html5.html')
    assert_equal :html5, r.doctype
    assert_equal 'http://code.dunae.ca/w3c_validators/test/valid_html5.html', r.uri
    assert_no_errors r
    assert_no_warnings r
    assert r.is_valid?
  end

  def test_validating_uri
    r = @v.validate_uri('http://code.dunae.ca/w3c_validators/test/invalid_html5.html')
    assert_errors r, 2
    assert_warnings r, 1
    assert !r.is_valid?
  end

  def test_validating_file
    file = File.dirname(__FILE__) + '/fixtures/invalid_html5.html'
    r = @v.validate_file(file)
    assert_errors r, 1
  end

  def test_validating_text
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
