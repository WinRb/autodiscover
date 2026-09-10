source 'https://rubygems.org'

# Specify your gem's dependencies in autodiscover.gemspec
gemspec

group :development do
  gem "rubocop", require: false
  gem "rubocop-rake", require: false
  gem "bundler-audit", "~> 0.9.3", require: false
  gem "ruby_audit", "~> 3.1", require: false if RUBY_VERSION >= "3.1.0"
end
