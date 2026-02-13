# frozen_string_literal: true

module Nonnative
  # Base configuration for a runnable unit managed by Nonnative.
  #
  # This class holds connection and timing attributes common to processes, servers and services,
  # as well as a nested {Nonnative::ConfigurationProxy} describing how/if a proxy should be started.
  #
  # Instances of this type are typically created via {Nonnative::Configuration#process},
  # {Nonnative::Configuration#server}, or {Nonnative::Configuration#service}.
  #
  # @see Nonnative::ConfigurationProcess
  # @see Nonnative::ConfigurationServer
  # @see Nonnative::ConfigurationService
  class ConfigurationRunner
    # @return [String, nil] runner name used for lookup (for example via `pool.process_by_name`)
    # @return [String] host to bind/connect to (defaults to `"0.0.0.0"`)
    # @return [Integer] port to bind/connect to
    # @return [Numeric] wait interval (seconds) used by runners between lifecycle steps
    attr_accessor :name, :host, :port, :wait

    # Proxy configuration for this runner.
    #
    # Note that this returns a configuration object even if no proxy is enabled; by default
    # the proxy kind is `"none"`.
    #
    # @return [Nonnative::ConfigurationProxy]
    attr_reader :proxy

    # Creates a runner configuration with defaults.
    #
    # Defaults:
    # - `host`: `"0.0.0.0"`
    # - `port`: `0`
    # - `wait`: `0.1`
    # - `proxy`: a new {Nonnative::ConfigurationProxy} with its own defaults
    #
    # @return [void]
    def initialize
      self.host = '0.0.0.0'
      self.port = 0
      self.wait = 0.1

      @proxy = Nonnative::ConfigurationProxy.new
    end

    # Sets proxy configuration using a hash-like value.
    #
    # This is primarily used when loading YAML configuration files, where proxy attributes are
    # represented as scalar values.
    #
    # @param value [Hash] proxy attributes
    # @option value [String] :kind proxy kind name (for example `"fault_injection"`)
    # @option value [String] :host proxy bind host (optional)
    # @option value [Integer] :port proxy bind port
    # @option value [String] :log proxy log file path
    # @option value [Numeric] :wait wait interval (seconds) after state changes (optional)
    # @option value [Hash] :options proxy implementation specific options
    # @return [void]
    def proxy=(value)
      proxy.kind = value[:kind]
      proxy.host = value[:host] if value[:host]
      proxy.port = value[:port]
      proxy.log = value[:log]
      proxy.wait = value[:wait] if value[:wait]
      proxy.options = value[:options]
    end
  end
end
