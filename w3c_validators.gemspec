# -*- encoding: utf-8 -*-
require File.expand_path('../lib/w3c_validators.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Alex Dunae"]
  gem.summary       = "A Ruby wrapper for the World Wide Web Consortium’s online validation services."
  gem.homepage      = "https://github.com/alexdunae/w3c_validators"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test}/*`.split("\n")
  gem.name          = "w3c_validators"
  gem.require_paths = ["lib"]
  gem.version       = W3CValidators::Validator::VERSION

  gem.add_dependency 'nokogiri'
end
