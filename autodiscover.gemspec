# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'autodiscover/version'

Gem::Specification.new do |s|
  s.name = 'autodiscover'
  s.version = Autodiscover::VERSION
  s.license = 'MIT'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.summary = "Ruby client for Microsoft's Autodiscover Service"
  s.description = 'The Autodiscover Service provides information about a ' \
                  'Microsoft Exchange environment such as service URLs, ' \
                  'versions and many other attributes.'
  # Note: this floor is intentionally conservative — CI starts at Ruby 3.0, but the gem likely
  # still works on older Rubies. Don't raise it just to satisfy lint or match CI without evidence of breakage.
  s.required_ruby_version = '>= 2.1.0'

  s.authors = ['David King', 'Dan Wanek']
  s.email = ['dking@bestinclass.com', 'dan.wanek@gmail.com']
  s.homepage = 'http://github.com/WinRb/autodiscover'

  s.files = `git ls-files -z`.split("\x0")
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_runtime_dependency 'httpclient'
  # logger is no longer a bundled gem on Ruby 4.0
  s.add_runtime_dependency 'logger'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'nori'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'minitest', '~> 5.6.0'
  s.add_development_dependency 'mocha', '~> 1.1.0'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rake'
end
