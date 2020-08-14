# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'nonnative/version'

Gem::Specification.new do |spec|
  spec.name          = 'nonnative'
  spec.version       = Nonnative::VERSION
  spec.authors       = ['Alex Falkowski']
  spec.email         = ['alexrfalkowski@gmail.com']

  spec.summary       = 'Allows you to keep using the power of ruby to test other systems'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/alexfalkowski/nonnative'
  spec.license       = 'Unlicense'
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = ['>= 2.0.0', '< 2.8.0']

  spec.add_dependency 'concurrent-ruby', '~> 1.0', '>= 1.0.5'
  spec.add_dependency 'cucumber', ['>= 4', '< 5']
  spec.add_dependency 'grpc', ['>= 1', '< 2']
  spec.add_dependency 'puma', '~> 4.3', '>= 4.3.3'
  spec.add_dependency 'rest-client', '~> 2.1'
  spec.add_dependency 'rspec-benchmark', '~> 0.6.0'
  spec.add_dependency 'rspec-expectations', '~> 3.9', '>= 3.9.2'
  spec.add_dependency 'sinatra', '~> 2.0', '>= 2.0.8.1'

  spec.add_development_dependency 'bundler', '~> 2.1', '>= 2.1.4'
  spec.add_development_dependency 'grpc-tools', ['>= 1', '< 2']
  spec.add_development_dependency 'rake', '~> 13.0', '>= 13.0.1'
  spec.add_development_dependency 'rubocop', '~> 0.88'
  spec.add_development_dependency 'simplecov', '~> 0.17.1'
  spec.add_development_dependency 'solargraph', '~> 0.39.11'
end
