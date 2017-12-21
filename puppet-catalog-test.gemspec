Gem::Specification.new do |s|
  s.name = 'puppet-catalog-test'
  s.version = '0.4.3'
  s.homepage = 'https://github.com/invadersmustdie/puppet-catalog-test/'
  s.summary = 'Test all your puppet catalogs for compiler warnings and errors'
  s.description = 'Test all your puppet catalogs for compiler warnings and errors.'

  s.executables = ['puppet-catalog-test']

  s.files = [
    'bin/puppet-catalog-test',
    'LICENSE',
    'Rakefile',
    'README.md',
    'puppet-catalog-test.gemspec'
  ]

  s.files += Dir["lib/**/*"]

  s.add_dependency 'puppet'
  s.add_dependency 'parallel'
  s.add_dependency 'builder'

  s.authors = ['Rene Lengwinat']
  s.email = 'rene.lengwinat@googlemail.com'
  s.license = 'MIT'
end
