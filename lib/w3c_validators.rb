require 'lib/markup_validator/markup_validator'
require 'lib/markup_validator/results'
require 'lib/markup_validator/message'

module W3CValidators

  # Validate an URL against the W3C validator.
  #
  # This method provides a quick validation but does not return any error details.
  #
  # ==== Example
  #   v = HTMLValidator.validate('http://example.com/test.html')
  #
  #   puts v.errors.length
  #   => 5
  #
  #   puts v.errors[0].to_s
  #   => "ERROR: line 6, col 73: end tag for "link" omitted, but OMITTAG NO was specified"
  def self.validate_markup(url, options={})
    MarkupValidator.validate(url, options)
  end

  # Validate an URL against the W3C validator using an HTTP HEAD request.
  #
  # This method provides a quick validation but does not return any error or warning details.
  #
  # ==== Example
  #   v = HTMLValidator.quick_validate('http://example.com/test.html')
  #
  #   puts v.errors.length
  #   => 5
  #
  #   puts v.errors[0].explanation
  #   => nil
  def self.quick_validate(url, options={})
    Validator.quick_validate(url, options)
  end
end