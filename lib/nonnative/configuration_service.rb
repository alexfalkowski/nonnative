# frozen_string_literal: true

module Nonnative
  # Service-specific configuration.
  #
  # A "service" is proxy-only: it does not start a Ruby thread or OS process. It exists so Nonnative can
  # start and control a proxy in front of an external dependency.
  #
  # Instances are usually created through {Nonnative::Configuration#service}.
  #
  # @see Nonnative::Configuration
  # @see Nonnative::Service
  class ConfigurationService < ConfigurationRunner
    # @return [Integer] client-facing port used by the service proxy
    attr_accessor :port

    # Creates a service configuration with defaults.
    #
    # @return [void]
    def initialize
      super

      self.port = 0
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
  end
end
