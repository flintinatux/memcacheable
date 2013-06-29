# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'memcacheable/version'

Gem::Specification.new do |spec|
  spec.name          = 'memcacheable'
  spec.version       = Memcacheable::VERSION
  spec.authors       = ['Scott McCormack']
  spec.email         = ['flintinatux@gmail.com']
  spec.description   = %q{A Rails concern to make caching ActiveRecord objects as dead-simple as possible. Uses the built-in Rails.cache mechanism, and implements the new finder methods available in Rails 4.0 to ensure maximum future compatibility.}
  spec.summary       = spec.description
  spec.homepage      = 'https://github.com/flintinatux/memcacheable'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord',  '>= 4.0.0'
  spec.add_dependency 'activesupport', '>= 4.0.0'

  spec.add_development_dependency 'activemodel', '>= 4.0.0'
  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.13'
end
