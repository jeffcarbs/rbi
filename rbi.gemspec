# frozen_string_literal: true
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbi/version'

Gem::Specification.new do |spec|
  spec.name          = 'rbi'
  spec.version       = RBI::VERSION
  spec.authors       = ['Alexandre Terrasa']
  spec.email         = ['alexandre.terrasa@shopify.com']

  spec.summary       = 'RBI related tools.'
  spec.homepage      = 'https://github.com/Shopify/rbi'
  spec.license       = 'MIT'

  spec.bindir        = 'exe'
  spec.executables   = %w[rbi]
  spec.require_paths = ['lib']

  spec.files         = Dir.glob(['lib/**/*.rb']) + %w[
    README.md
    Gemfile
    Rakefile
  ]

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'

  spec.add_development_dependency('bundler', '~> 1.17')
  spec.add_development_dependency('minitest', '~> 5.0')
  spec.add_development_dependency('rake', '~> 13.0.1')

  spec.add_dependency('colorize')
  spec.add_dependency('sorbet', '~> 0.5.5')
  spec.add_dependency('sorbet-runtime')
  spec.add_dependency('thor', '>= 0.19.2')

  spec.required_ruby_version = '>= 2.3.7'
end
