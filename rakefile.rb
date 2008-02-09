require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'lib/w3c_validators'
require 'fileutils'

include W3CValidators

desc 'Run the unit tests.'
Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.libs << 'lib/test'
  t.test_files = FileList['test/test*.rb'].exclude('test_helper.rb')
  t.verbose = false
end


desc 'Generate documentation for W3C Validators.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'Ruby W3C Validators'
  rdoc.options << '--all' << '--inline-source' << '--line-numbers'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/*.rb')
  rdoc.rdoc_files.include('lib/w3c_validators/*.rb')
end


spec = Gem::Specification.new do |s| 
  s.name = "w3c_validators"
  s.version = "0.9.1"
  s.author = "Alex Dunae"
  s.homepage = "http://code.dunae.ca/w3c_validators"
  s.platform = Gem::Platform::RUBY
  s.description = <<-EOF
    W3C Validators is a Ruby wrapper for the World Wide Web Consortium's online validation services.
  EOF
  s.summary = "Wrapper for the World Wide Web Consortium's online validation services."
  s.files = FileList["{lib}/**/*"].to_a
  s.test_files = Dir.glob('test/test_*.rb') 
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.rdoc_options << '--all' << '--inline-source' << '--line-numbers'
end

desc 'Build the W3C Validators gem.'
Rake::GemPackageTask.new(spec) do |pkg| 
  pkg.need_zip = true
  pkg.need_tar = true 
end 