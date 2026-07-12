# frozen_string_literal: true

module Nonnative
  # Service-specific configuration.
  #
  # A "service" represents an externally managed dependency. It does not start a Ruby thread or OS
  # process. It can wait for TCP readiness and can optionally run a proxy in front of the dependency.
  #
  # Instances are usually created through {Nonnative::Configuration#service}.
  #
  # @see Nonnative::Configuration
  # @see Nonnative::Service
  class ConfigurationService < ConfigurationRunner
    # @return [Integer] client-facing dependency port, used as the listener when a proxy is enabled
    attr_accessor :port

    # @return [Numeric] readiness timeout (seconds) used when waiting for service readiness
    attr_accessor :timeout

    # Proxy configuration for this service.
    #
    # @return [Nonnative::ConfigurationProxy]
    attr_reader :proxy

    # @return [Array<Nonnative::ConfigurationServiceReadiness>] optional service readiness checks
    attr_reader :readiness

    # Creates a service configuration with defaults.
    #
    # @return [void]
    def initialize
      super

      self.port = 0
      self.timeout = DEFAULT_TIMEOUT
      @readiness = []
      @proxy = Nonnative::ConfigurationProxy.new
    end

    # Sets optional service readiness checks.
    #
    # @param value [Array<Hash, #to_h>, nil] readiness checks with required `kind`, `host`, and `port`
    # @return [void]
    def readiness=(value)
      @readiness = value.nil? ? [] : build_readiness(value)
    end

    # Sets proxy configuration using a hash-like value.
    #
    # This is primarily used when loading YAML configuration files, where proxy attributes are
    # represented as scalar values.
    #
    # @param value [Hash] proxy attributes
    # @option value [String] :kind proxy kind name (for example `"fault_injection"`)
    # @option value [String] :host upstream host behind the proxy (optional)
    # @option value [Integer] :port upstream port behind the proxy
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

    # Services expose a single proxy listener, so plural runner ports are not supported.
    #
    # @return [void]
    # @raise [ArgumentError] when plural service ports are read
    def ports
      raise ArgumentError, "Use 'port' instead of 'ports' for service '#{name}'"
    end

    # Services expose a single proxy listener, so plural runner ports are not supported.
    #
    # @param _value [Array<Integer>] ignored plural ports
    # @return [void]
    # @raise [ArgumentError] when plural service ports are assigned
    def ports=(_value)
      raise ArgumentError, "Use 'port' instead of 'ports' for service '#{name}'"
    end

    private

    def build_readiness(value)
      raise ArgumentError, 'Service readiness must be a list of checks' unless value.is_a?(Array)

      value.map { |check| Nonnative::ConfigurationServiceReadiness.new(check) }
    end
  end
end
