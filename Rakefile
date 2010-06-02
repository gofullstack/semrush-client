require 'rubygems'
require 'fileutils'

begin
  require 'jeweler'
rescue LoadError
  puts "Jeweler not available. Install it with gem install jeweler"
end

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "semrush-client"
  gemspec.description = "Client for the SEMRush API"
  gemspec.summary = "Connect to SEMRush API to access domain and keyword SEO information"
  gemspec.email = "support@cramerdev.com"
  gemspec.homepage = "http://cramerdev.com/"
  gemspec.authors = ["Cramer Development"]
  gemspec.add_dependency('active_support', '>= 2.0.2')
end

require 'rake/testtask'
Rake::TestTask.new

task :default => :test
