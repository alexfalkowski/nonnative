# frozen_string_literal: true

module Nonnative
  # Runtime runner for an external dependency.
  #
  # A service runner does not manage an OS process or Ruby thread. It exists so Nonnative can manage
  # a proxy lifecycle (start/stop/reset) for an external service that is managed elsewhere (for example
  # a database running in Docker).
  #
  # The underlying configuration is a {Nonnative::ConfigurationService}.
  #
  # @see Nonnative::ConfigurationService
  # @see Nonnative::Proxy
  class Service < Runner
    # Returns the proxy instance for this service.
    #
    # @return [Nonnative::Proxy]
    attr_reader :proxy

    # @param service [Nonnative::ConfigurationService] service configuration
    def initialize(service)
      super

      @proxy = Nonnative::ProxyFactory.create(service)
    end

    # Returns configured service readiness checks.
    #
    # @return [Array<Nonnative::ConfigurationServiceReadiness>]
    def readiness
      service.readiness
    end

    # Returns the configured service readiness timeout.
    #
    # @return [Numeric]
    def timeout
      service.timeout
    end

    # Starts the configured proxy (if any).
    #
    # @return [void]
    def start
      proxy.start

      Nonnative.logger.info "started service '#{service.name}'"
    end

    # Stops the configured proxy (if any).
    #
    # @return [void]
    def stop
      proxy.stop

      Nonnative.logger.info "stopped service '#{service.name}'"
    end
  end
end
