# frozen_string_literal: true

module Nonnative
  # Parent type for proxy implementations.
  #
  # A proxy is responsible for interposing behavior between a client and a target service.
  # Runtime services create a proxy instance via {Nonnative::ProxyFactory} based on `service.proxy.kind`.
  #
  # Service configuration `host` and `port` are the client-facing endpoint. Concrete proxy methods are
  # implementation-specific; for example {Nonnative::FaultInjectionProxy#host} and
  # {Nonnative::FaultInjectionProxy#port} return the upstream target behind the proxy.
  #
  # Concrete proxies typically implement these public methods:
  # - `start`: begin proxying (bind/listen, start threads, etc)
  # - `stop`: stop proxying and release resources
  # - `reset`: return proxy behavior to a healthy/default state
  #
  # @see Nonnative::ProxyFactory
  # @see Nonnative::NoProxy
  # @see Nonnative::FaultInjectionProxy
  class Proxy
    # @param service [Nonnative::ConfigurationService] service configuration with an attached proxy configuration
    def initialize(service)
      @service = service
    end

    protected

    # Returns the underlying runner configuration.
    #
    # @return [Nonnative::ConfigurationRunner]
    attr_reader :service

    # Sleeps for the proxy wait interval configured on `service.proxy.wait`.
    #
    # Proxies can use this to allow state transitions to take effect.
    #
    # @return [void]
    def wait
      sleep service.proxy.wait
    end
  end
end
