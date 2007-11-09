require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'lib/w3c_validators'
include W3CValidators

#desc 'Default: parse a URL.'
task :default => [:validate]

desc 'Check a file against the W3C\'s markup validation service.'
task :validate do

  url = ENV['url']
  
  if !url or url.empty?
    puts 'Usage: rake validate url=http://example.com/'
    exit
  end
  
  v = MarkupValidator.new
  
  results = v.validate_uri(url, false)
  puts "Errors:" + results.errors.length.to_s

  puts "Warnings: " + results.warnings.length.to_s
  
  puts "DOCTYPE: #{results.doctype}"
  puts "Validity: #{results.validity}"
end

desc 'Run the unit tests.'
Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'lib/test'
  t.test_files = FileList['test/test*.rb'].exclude('test_helper.rb')
  t.verbose = false
end


desc 'Generate documentation for the W3C Validators.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'Ruby W3C Validators'
  rdoc.options << '--all'
  rdoc.options << '--inline-source'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('LICENSE')
  #rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('lib/markup_validator/*.rb')
end
