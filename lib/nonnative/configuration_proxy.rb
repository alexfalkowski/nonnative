# frozen_string_literal: true

module Nonnative
  # Proxy configuration attached to a runner configuration.
  #
  # A proxy allows you to interpose behavior between a client and a real service. For example,
  # the built-in `"fault_injection"` proxy can close connections, introduce delays, or corrupt data
  # for resilience testing.
  #
  # This object is created automatically for each runner via {Nonnative::ConfigurationRunner}.
  # When `kind` is set to `"none"`, no proxy is started and the runner will use its configured
  # `host`/`port` directly.
  #
  # @see Nonnative::ConfigurationRunner#proxy
  # @see Nonnative.proxies
  class ConfigurationProxy
    # @return [String] proxy kind name (for example `"none"` or `"fault_injection"`)
    # @return [String] proxy bind host (defaults to `"0.0.0.0"`)
    # @return [Integer] proxy bind port (defaults to `0`)
    # @return [String, nil] path to proxy log file (implementation-dependent)
    # @return [Numeric] wait interval (seconds) after proxy state changes (defaults to `0.1`)
    # @return [Hash] proxy implementation options (implementation-dependent)
    attr_accessor :kind, :host, :port, :log, :wait, :options

    # Creates a proxy configuration with defaults.
    #
    # Defaults:
    # - `kind`: `"none"`
    # - `host`: `"0.0.0.0"`
    # - `port`: `0`
    # - `wait`: `0.1`
    # - `options`: `{}`
    #
    # @return [void]
    def initialize
      self.kind = 'none'
      self.host = '0.0.0.0'
      self.port = 0
      self.wait = 0.1
      self.options = {}
    end
  end
end
