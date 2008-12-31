# Auto-generated gemspec
# Run 'rake generate_gemspec' to re-generate
Gem::Specification.new do |s|
  s.name     = "w3c_validators"
  s.platform = Gem::Platform::RUBY
  s.version  = "1.0.0"
  s.date     = "2008-12-31"
  s.summary  = "Wrapper for the World Wide Web Consortium's online validation services."
  s.email    = "code@dunae.ca"
  s.homepage = "http://code.dunae.ca/w3c_validators"
  s.description = "W3C Validators is a Ruby wrapper for the World Wide Web Consortium's online validation services."
  s.has_rdoc = true
  s.author  = "Alex Dunae"
  s.extra_rdoc_files = ['README.rdoc', 'CHANGELOG', 'LICENSE']
  s.rdoc_options << '--all' << '--inline-source' << '--line-numbers' << '--charset' << 'utf-8'
  s.test_files = ['test/test_css_validator.rb','test/test_exceptions.rb','test/test_feed_validator.rb','test/test_helper.rb','test/test_html5_validator.rb','test/test_markup_validator.rb']
  s.files = ['lib/w3c_validators','lib/w3c_validators.rb','lib/w3c_validators/constants.rb','lib/w3c_validators/css_validator.rb','lib/w3c_validators/exceptions.rb','lib/w3c_validators/feed_validator.rb','lib/w3c_validators/markup_validator.rb','lib/w3c_validators/message.rb','lib/w3c_validators/nu_validator.rb','lib/w3c_validators/results.rb','lib/w3c_validators/validator.rb']
end
