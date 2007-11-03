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
  
  #results = v.validate_file('test.html', false)

  results = v.validate_uri(url, false)
  puts "ERRORS?"
  puts results.errors.length

  puts "WARNINGS?"
  puts results.warnings.length
  
  puts results.errors[0].to_s

  #results.errors.each do |err|
    #puts "ERROR: #{err.line}: #{err.source}"
  #  puts err.to_s
  #end
  
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


desc 'Generate documentation for the HTMLalidator.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'HTMLValidator'
  rdoc.options << '--all'
  rdoc.options << '--inline-source'
  rdoc.options << '--line-numbers'
  #rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('LICENSE')
  #rdoc.rdoc_files.include('CHANGELOG')
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('lib/markup_validator/*.rb')
end
