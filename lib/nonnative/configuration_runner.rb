# frozen_string_literal: true

module Nonnative
  # Base configuration for a runnable unit managed by Nonnative.
  #
  # This class holds connection and timing attributes common to processes, servers and services.
  #
  # Instances of this type are typically created via {Nonnative::Configuration#process},
  # {Nonnative::Configuration#server}, or {Nonnative::Configuration#service}.
  #
  # @see Nonnative::ConfigurationProcess
  # @see Nonnative::ConfigurationServer
  # @see Nonnative::ConfigurationService
  class ConfigurationRunner
    # @return [String, nil] runner name used for lookup (for example via `pool.process_by_name`)
    # @return [String] host to bind/connect to (defaults to `"127.0.0.1"`)
    # @return [Array<Integer>] ports to bind/connect to
    # @return [Numeric] wait interval (seconds) used by runners between lifecycle steps
    attr_accessor :name, :host, :wait

    # @return [Array<Integer>] client-facing ports used for readiness/shutdown checks
    attr_reader :ports

    # Creates a runner configuration with defaults.
    #
    # Defaults:
    # - `host`: `"127.0.0.1"`
    # - `ports`: `[0]`
    # - `wait`: `0.1`
    #
    # @return [void]
    def initialize
      self.host = '127.0.0.1'
      @ports = [0]
      self.wait = 0.1
    end

    # Sets the client-facing ports for this runner.
    #
    # @param value [Array<Integer>] ports to check for readiness/shutdown
    # @return [void]
    def ports=(value)
      @ports = Array(value)
    end

    # Returns the primary client-facing port.
    #
    # This preserves a single endpoint for client helpers while the public configuration contract uses {#ports}.
    #
    # @return [Integer]
    def port
      ports.first
    end
  end
end
