version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.name    = 'autodiscover'
  s.version = version
  s.summary = "Ruby client for Microsoft's Autodiscover Service"
  s.description = 'Library to find the Autodiscover server and to get from it the URLs and settings needed to access Web services available from Exchange servers.'
  s.required_ruby_version = '>= 1.8.7'

  s.author   = 'David King'
  s.email    = 'dking@bestinclass.com'
  s.homepage = 'http://github.com/wimm/autodiscover'

  s.files = Dir['CHANGELOG', 'README.md', 'MIT-LICENSE', 'lib/**/*']
  s.extra_rdoc_files = ['MIT-LICENSE', 'README.md']
  s.test_files = Dir['test/*.rb']

  s.add_runtime_dependency  'nokogiri'
  s.add_runtime_dependency  'httpclient'
  s.add_development_dependency 'webmock'
end
