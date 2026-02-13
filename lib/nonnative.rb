# frozen_string_literal: true

# = Nonnative
#
# Nonnative is a Ruby-first harness for end-to-end testing of services implemented in other languages.
# It can:
#
# - start external processes and in-process servers
# - wait for readiness via port checks
# - optionally run fault-injection proxies in front of services
#
# The public entry points are exposed as module-level methods on {Nonnative}.
#
# == Basic usage
#
# Configure the system under test:
#
#   Nonnative.configure do |config|
#     config.name = 'example'
#     config.url = 'http://127.0.0.1:8080'
#     config.log = 'test.log'
#
#     config.process do |p|
#       p.name = 'api'
#       p.command = -> { './bin/api' }
#       p.host = '127.0.0.1'
#       p.port = 8080
#       p.timeout = 10
#       p.log = 'api.log'
#     end
#   end
#
# Start and stop around your test suite:
#
#   Nonnative.start
#   # run tests...
#   Nonnative.stop
#
# == Notes
#
# This file also requires integration helpers used by acceptance tests. If you require `nonnative` outside a
# Cucumber runtime, loading `nonnative/cucumber` may not be desirable for your environment.
#
require 'socket'
require 'timeout'
require 'yaml'
require 'open3'
require 'securerandom'

require 'grpc'
require 'sinatra'
require 'rest-client'
require 'retriable'
require 'concurrent'
require 'config'
require 'cucumber'
require 'get_process_mem'
require 'rspec-benchmark'
require 'rspec/expectations'
require 'rspec/wait'
require 'puma'
require 'puma/server'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/start_error'
require 'nonnative/stop_error'
require 'nonnative/not_found_error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/configuration'
require 'nonnative/configuration_runner'
require 'nonnative/configuration_process'
require 'nonnative/configuration_server'
require 'nonnative/configuration_service'
require 'nonnative/configuration_proxy'
require 'nonnative/runner'
require 'nonnative/process'
require 'nonnative/server'
require 'nonnative/service'
require 'nonnative/pool'
require 'nonnative/http_client'
require 'nonnative/http_server'
require 'nonnative/http_proxy_server'
require 'nonnative/grpc_server'
require 'nonnative/observability'
require 'nonnative/proxy_factory'
require 'nonnative/proxy'
require 'nonnative/no_proxy'
require 'nonnative/fault_injection_proxy'
require 'nonnative/socket_pair'
require 'nonnative/close_all_socket_pair'
require 'nonnative/delay_socket_pair'
require 'nonnative/invalid_data_socket_pair'
require 'nonnative/socket_pair_factory'
require 'nonnative/go_command'
require 'nonnative/cucumber'
require 'nonnative/header'

# The main namespace for the gem.
#
# Most consumers will interact with module-level methods:
#
# - {Nonnative.configure} / {Nonnative.configuration}
# - {Nonnative.start} / {Nonnative.stop}
# - {Nonnative.clear} / {Nonnative.reset}
#
# @see Nonnative::Configuration for the configuration DSL
# @see Nonnative::Pool for lifecycle orchestration once started
module Nonnative
  class << self
    # Returns the current runner pool (created on {Nonnative.start}).
    #
    # @return [Nonnative::Pool, nil] the pool instance, or `nil` if not started yet
    attr_reader :pool

    # Loads one or more configuration files using the `config` gem.
    #
    # This is primarily used by {Nonnative::Configuration#load_file}, but is public for advanced cases.
    #
    # @param files [Array<String>] paths to configuration files
    # @return [Config::Options] the loaded configuration object
    def configurations(*files)
      Config.load_files(files)
    end

    # Returns the current configuration (memoized).
    #
    # @return [Nonnative::Configuration]
    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    # Yields the configuration to a block for programmatic setup.
    #
    # @yieldparam config [Nonnative::Configuration]
    # @return [void]
    #
    # @example
    #   Nonnative.configure do |config|
    #     config.name = 'my-service'
    #     # ...
    #   end
    def configure
      yield configuration
    end

    # Returns the gem logger (memoized).
    #
    # The logger writes to the path configured at {Nonnative::Configuration#log}.
    #
    # @return [Logger]
    def logger
      @logger ||= Logger.new(configuration.log)
    end

    # Reads a file and returns only lines matching the given predicate.
    #
    # @param path [String] file path to read
    # @param predicate [#call] callable that receives a line and returns truthy/falsey
    # @return [Array<String>] matching lines
    def log_lines(path, predicate)
      File.readlines(path).select { |l| predicate.call(l) }
    end

    # Builds a Go test executable command line with optional profiling/trace/coverage flags.
    #
    # This is used when process configuration specifies a `go` section.
    #
    # @param tools [Array<String>] enabled tool names (e.g. `["prof", "trace", "cover"]`)
    # @param output [String] directory where outputs should be written
    # @param exec [String] the test binary (or wrapper) to execute
    # @param cmd [String] the command argument passed to the test binary
    # @param params [Array<String>] extra parameters for the command
    # @return [String] executable command string
    def go_executable(tools, output, exec, cmd, *params)
      Nonnative::GoCommand.new(tools, exec, output).executable(cmd, params)
    end

    # Returns an HTTP client for common health/readiness endpoints.
    #
    # @return [Nonnative::Observability]
    def observability
      @observability ||= Nonnative::Observability.new(configuration.url)
    end

    # Returns the configured proxy kinds mapped to proxy classes.
    #
    # Consumers can extend this map to add custom proxy implementations.
    #
    # @return [Hash{String=>Class}]
    def proxies
      @proxies ||= { 'fault_injection' => Nonnative::FaultInjectionProxy }.freeze
    end

    # Resolves a proxy implementation for a configured kind.
    #
    # @param kind [String] proxy kind name (for example `"fault_injection"`)
    # @return [Class] a subclass of {Nonnative::Proxy}
    def proxy(kind)
      Nonnative.proxies[kind] || Nonnative::NoProxy
    end

    # Starts all configured services, servers, and processes, and waits for readiness.
    #
    # Readiness is determined by attempting to connect to each runner's configured host/port.
    #
    # @return [void]
    # @raise [Nonnative::StartError] if one or more runners fail to start or become ready in time
    def start
      @pool ||= Nonnative::Pool.new(configuration)
      errors = []

      @pool.start do |name, values, result|
        id, started = values
        errors << "Started #{name} with id #{id}, though did respond in time" if !started || !result
      end

      raise Nonnative::StartError, errors.join("\n") unless errors.empty?
    end

    # Stops all configured processes and servers, then services, and waits for shutdown.
    #
    # @return [void]
    # @raise [Nonnative::StopError] if one or more runners fail to stop in time
    def stop
      return if @pool.nil?

      errors = []

      @pool.stop do |name, id, result|
        errors << "Stopped #{name} with id #{id}, though did respond in time" unless result
      end

      raise Nonnative::StopError, errors.join("\n") unless errors.empty?
    end

    # Clears the memoized configuration instance.
    #
    # @return [void]
    def clear_configuration
      @configuration = nil
    end

    # Clears the memoized pool instance.
    #
    # @return [void]
    def clear_pool
      @pool = nil
    end

    # Clears memoized configuration and pool.
    #
    # @return [void]
    def clear
      clear_configuration
      clear_pool
    end

    # Resets proxies for all currently started runners.
    #
    # @return [void]
    # @raise [NoMethodError] if called before {Nonnative.start} (because {Nonnative.pool} is nil)
    def reset
      Nonnative.pool.reset
    end
  end
end
