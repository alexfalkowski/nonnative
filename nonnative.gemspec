# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'nonnative/version'

Gem::Specification.new do |spec|
  spec.name          = 'nonnative'
  spec.version       = Nonnative::VERSION
  spec.authors       = ['Alejandro Falkowski']
  spec.email         = ['alexrfalkowski@gmail.com']

  spec.summary       = 'Ruby-first end-to-end harness for testing systems implemented in other languages'
  spec.description   = 'Starts OS processes, in-process Ruby servers, and proxy-only services with TCP readiness checks and fault-injection proxies.'
  spec.homepage      = 'https://github.com/alexfalkowski/nonnative'
  spec.license       = 'MIT'
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = ['>= 4.0.0', '< 5.0.0']
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'concurrent-ruby', '>= 1', '< 2'
  spec.add_dependency 'config', '>= 5', '< 6'
  spec.add_dependency 'cucumber', '>= 7', '< 12'
  spec.add_dependency 'cucumber-cucumber-expressions', '< 19'
  spec.add_dependency 'get_process_mem', '>= 1', '< 2'
  spec.add_dependency 'grpc', '>= 1', '< 2'
  spec.add_dependency 'puma', '>= 7', '< 8'
  spec.add_dependency 'rest-client', '>= 2', '< 3'
  spec.add_dependency 'retriable', '>= 3', '< 4'
  spec.add_dependency 'rspec-benchmark', '>= 0', '< 1'
  spec.add_dependency 'rspec-expectations', '>= 3', '< 4'
  spec.add_dependency 'rspec-wait', '>= 1', '< 2'
  spec.add_dependency 'sinatra', '>= 4', '< 5'
end
