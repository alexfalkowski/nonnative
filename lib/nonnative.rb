# frozen_string_literal: true

# = Nonnative
#
# Nonnative is a Ruby-first harness for end-to-end testing of services implemented in other languages.
# It can:
#
# - start external processes and in-process servers
# - wait for readiness via port checks, optional process HTTP/gRPC readiness, and optional service TCP readiness
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
#       p.ports = [8080, 9090]
#       p.timeout = 10
#       p.log = 'api.log'
#       p.readiness = [{ kind: 'http', port: 8080, path: '/example/readyz' }]
#     end
#   end
#
# Start and stop around your test suite:
#
#   Nonnative.start
#   # run tests...
#   Nonnative.stop
#
# == Cucumber integration
#
# Requiring `nonnative` loads the lazy Cucumber integration. It is safe outside a booted Cucumber
# runtime; hooks and step definitions are installed once Cucumber's Ruby DSL is ready.
#
require 'socket'
require 'timeout'
require 'yaml'
require 'open3'
require 'securerandom'
require 'shellwords'
require 'uri'
require 'openssl'
require 'json'
require 'time'
require 'singleton' # ruby-paseto depends on this stdlib, which Ruby no longer auto-loads

require 'grpc'
require 'grpc/health/v1/health_services_pb'
require 'sinatra'
require 'rest-client'
require 'retriable'
require 'concurrent'
require 'config'
require 'get_process_mem'
require 'rspec-benchmark'
require 'rspec/expectations'
require 'rspec/wait'
require 'puma'
require 'puma/server'

# jwt-eddsa (with the ed25519 gem) and ssh_data are pure Ruby and need no system library, so they load
# here. PASETO's rbnacl needs system libsodium, so Nonnative::PasetoToken requires it lazily instead.
require 'jwt/eddsa'
require 'ssh_data'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/start_error'
require 'nonnative/stop_error'
require 'nonnative/not_found_error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/ports'
require 'nonnative/configuration_file'
require 'nonnative/configuration'
require 'nonnative/configuration_runner'
require 'nonnative/configuration_readiness'
require 'nonnative/configuration_service_readiness'
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
require 'nonnative/tcp_probe'
require 'nonnative/http_probe'
require 'nonnative/grpc_health'
require 'nonnative/grpc_probe'
require 'nonnative/http_service'
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
require 'nonnative/reset_peer_socket_pair'
require 'nonnative/delay_socket_pair'
require 'nonnative/timeout_socket_pair'
require 'nonnative/invalid_data_socket_pair'
require 'nonnative/bandwidth_socket_pair'
require 'nonnative/limit_data_socket_pair'
require 'nonnative/socket_pair_factory'
require 'nonnative/go_executable'
require 'nonnative/cucumber'
require 'nonnative/header'
require 'nonnative/ed25519_key'
require 'nonnative/jwt_token'
require 'nonnative/paseto_token'
require 'nonnative/ssh_token'
require 'nonnative/token'

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
    # Returns or overrides the current runner pool (created on {Nonnative.start}).
    #
    # @return [Nonnative::Pool, nil] the pool instance, or `nil` if not started yet
    attr_accessor :pool

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

    # Builds a Go test executable command string with optional profiling/trace/coverage flags.
    #
    # Use this when passing a command string directly to `spawn`.
    #
    # @param tools [Array<String>] enabled tool names (e.g. `["prof", "trace", "cover"]`)
    # @param output [String] directory where outputs should be written
    # @param exec [String] the test binary (or wrapper) to execute
    # @param cmd [String] the command argument passed to the test binary
    # @param params [Array<String>] extra parameter strings for the command
    # @return [String] executable command string
    def go_command(tools, output, exec, cmd, *params)
      Nonnative::GoExecutable.new(tools, exec, output).command(cmd, *params)
    end

    # Builds a Go test executable argv array with optional profiling/trace/coverage flags.
    #
    # Use this when passing argv entries directly to `spawn`.
    #
    # @param tools [Array<String>] enabled tool names (e.g. `["prof", "trace", "cover"]`)
    # @param output [String] directory where outputs should be written
    # @param exec [String] the test binary (or wrapper) to execute
    # @param cmd [String] the command argument passed to the test binary
    # @param params [Array<String>] extra parameter strings for the command
    # @return [Array<String>] executable argv entries
    def go_argv(tools, output, exec, cmd, *params)
      Nonnative::GoExecutable.new(tools, exec, output).argv(cmd, *params)
    end

    # Builds a token generator for authenticating against a service under test.
    #
    # The signing parameters are passed in directly; this is not coupled to any service's
    # configuration format. The generated token string is ready for {Nonnative::Header.auth_bearer}.
    #
    # @param kind [String] token kind, one of `"jwt"`, `"paseto"`, or `"ssh"`
    # @param issuer [String] the `iss` claim (unused by the `ssh` kind)
    # @param key [String] the key id (JWT `kid` header, PASETO `kid` footer, or SSH `kid` claim)
    # @param private_key [String] path to the Ed25519 private key file (PKCS#8 PEM for `jwt`/`paseto`, OpenSSH format for `ssh`)
    # @param expiration [Integer] token lifetime in seconds (drives `exp`)
    # @return [Nonnative::Token]
    #
    # @example
    #   token = Nonnative.token(kind: 'jwt', issuer: 'iss', key: 'key-1', private_key: 'config/ed25519.pem', expiration: 3600)
    #   Nonnative::Header.auth_bearer(token.generate(aud: 'GET /v1/things', sub: 'user-1'))
    def token(kind:, issuer:, key:, private_key:, expiration:) = Nonnative::Token.new(kind:, issuer:, key:, private_key:, expiration:)

    # Returns an HTTP client for common health/readiness endpoints.
    #
    # @return [Nonnative::Observability]
    def observability = (@observability ||= Nonnative::Observability.new(configuration.url))

    # Returns a client helper for the standard gRPC health checking protocol.
    #
    # @param host [String] gRPC server host
    # @param port [Integer] gRPC server port
    # @param service [String] gRPC health service name
    # @param timeout [Numeric] default call timeout in seconds
    # @return [Nonnative::GRPCHealth]
    def grpc_health(host:, port:, service:, timeout: 1) = Nonnative::GRPCHealth.new(host: host, port: port, service: service, timeout: timeout)

    # Returns the configured proxy kinds mapped to proxy classes.
    #
    # Consumers can extend this map to add custom proxy implementations.
    #
    # @return [Hash{String=>Class}]
    def proxies
      @proxies ||= { 'fault_injection' => Nonnative::FaultInjectionProxy }
    end

    # Resolves a proxy implementation for a configured kind.
    #
    # `nil` and `"none"` resolve to {Nonnative::NoProxy}; any other kind must be registered in
    # {Nonnative.proxies}.
    #
    # @param kind [String] proxy kind name (for example `"fault_injection"`)
    # @return [Class] a subclass of {Nonnative::Proxy}
    # @raise [ArgumentError] if the kind is not `"none"` and has not been registered
    def proxy(kind)
      kind.nil? || kind == 'none' ? NoProxy : proxies.fetch(kind) { raise ArgumentError, "Unsupported proxy kind '#{kind}'" }
    end

    # Starts all configured services, servers, and processes, and waits for readiness.
    #
    # Readiness is determined by port checks, plus optional process HTTP/gRPC readiness and optional
    # service TCP readiness.
    #
    # @return [void]
    # @raise [Nonnative::StartError] if one or more runners fail to start or become ready in time
    def start
      @pool ||= Nonnative::Pool.new(configuration)
      errors = []
      errors.concat(@pool.start)
      nil
    rescue StandardError => e
      errors << unexpected_lifecycle_error(:start, e)
    ensure
      if errors.any?
        errors.concat(rollback_start)

        raise Nonnative::StartError, errors.join("\n")
      end
    end

    # Stops all configured processes and servers, then services, and waits for shutdown.
    #
    # @return [void]
    # @raise [Nonnative::StopError] if one or more runners fail to stop in time
    def stop
      errors = []
      return if @pool.nil?

      errors.concat(@pool.stop)
      nil
    rescue StandardError => e
      errors << unexpected_lifecycle_error(:stop, e)
    ensure
      raise Nonnative::StopError, errors.join("\n") unless errors.empty?
    end

    # Clears the memoized configuration instance.
    #
    # @return [void]
    def clear_configuration
      @configuration = nil
    end

    # Closes and clears the memoized logger instance.
    #
    # @return [void]
    def clear_logger
      @logger&.close
    ensure
      @logger = nil
    end

    # Clears the memoized observability client.
    #
    # @return [void]
    def clear_observability
      @observability = nil
    end

    # Clears the memoized pool instance.
    #
    # @return [void]
    def clear_pool
      @pool = nil
    end

    # Clears memoized configuration, logger, observability client, and pool.
    #
    # Call this before reconfiguring Nonnative or starting a new lifecycle in the same Ruby process.
    # `start`/`stop` are intended to manage one lifecycle for the current pool.
    #
    # @return [void]
    def clear
      clear_logger
      clear_observability
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

    private

    def rollback_start
      errors = []
      return errors if @pool.nil?

      errors.concat(@pool.rollback)
    rescue StandardError => e
      errors << unexpected_lifecycle_error(:rollback, e)
    ensure
      clear_pool if errors.empty?
    end

    def unexpected_lifecycle_error(action, error)
      "#{action.to_s.capitalize} failed with #{error.class}: #{error.message}"
    end
  end
end
