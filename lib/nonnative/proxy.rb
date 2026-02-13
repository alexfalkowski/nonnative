# frozen_string_literal: true

module Nonnative
  # Base class for proxy implementations.
  #
  # A proxy is responsible for interposing behavior between a client and a target service.
  # Runners ({Nonnative::Process}, {Nonnative::Server}, and {Nonnative::Service}) create a proxy
  # instance via {Nonnative::ProxyFactory} based on `service.proxy.kind`.
  #
  # Concrete proxies typically implement these public methods:
  # - `start`: begin proxying (bind/listen, start threads, etc)
  # - `stop`: stop proxying and release resources
  # - `reset`: return proxy behavior to a healthy/default state
  # - `host` / `port`: endpoint clients should connect to when the proxy is enabled
  #
  # @see Nonnative::ProxyFactory
  # @see Nonnative::NoProxy
  # @see Nonnative::FaultInjectionProxy
  class Proxy
    # @param service [Nonnative::ConfigurationRunner] runner configuration with an attached proxy configuration
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
