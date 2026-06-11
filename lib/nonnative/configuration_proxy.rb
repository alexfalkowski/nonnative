# frozen_string_literal: true

module Nonnative
  # Proxy configuration attached to a service configuration.
  #
  # A proxy allows you to interpose behavior between a client and a real service. For example,
  # the built-in `"fault_injection"` proxy can close connections, introduce delays, or corrupt data
  # for resilience testing.
  #
  # This object is created automatically for each service via {Nonnative::ConfigurationService}.
  # When `kind` is set to `"none"`, no proxy is started and the service will use its configured
  # `host`/`port` directly.
  #
  # @see Nonnative::ConfigurationService#proxy
  # @see Nonnative.proxies
  class ConfigurationProxy
    # @return [String] proxy kind name (for example `"none"` or `"fault_injection"`)
    # @return [String] upstream host used by proxy implementations (defaults to `"127.0.0.1"`)
    # @return [Integer] upstream port used by proxy implementations (defaults to `0`)
    # @return [String, nil] path to proxy log file (implementation-dependent)
    # @return [Numeric] wait interval (seconds) after proxy state changes (defaults to `0.1`)
    # @return [Hash] proxy implementation options (implementation-dependent)
    attr_accessor :kind, :host, :port, :log, :wait
    attr_reader :options

    # Creates a proxy configuration with defaults.
    #
    # Defaults:
    # - `kind`: `"none"`
    # - `host`: `"127.0.0.1"`
    # - `port`: `0`
    # - `wait`: `0.1`
    # - `options`: `{}`
    #
    # @return [void]
    def initialize
      self.kind = 'none'
      self.host = '127.0.0.1'
      self.port = 0
      self.wait = 0.1
      self.options = {}
    end

    # Stores proxy implementation options.
    #
    # Nil is normalized to an empty hash so callers loading partial configuration do not erase the
    # default options container.
    #
    # @param value [Hash, nil]
    # @return [void]
    def options=(value)
      @options = value || {}
    end
  end
end
