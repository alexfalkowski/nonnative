# frozen_string_literal: true

module Nonnative
  # Factory for creating proxy instances for runners.
  #
  # Each runtime runner ({Nonnative::Process}, {Nonnative::Server}, {Nonnative::Service}) constructs
  # a proxy via this factory. The proxy implementation is selected by `service.proxy.kind` and resolved
  # using {Nonnative.proxy}.
  #
  # If the kind is unknown (or `"none"`), {Nonnative.proxy} returns {Nonnative::NoProxy}.
  #
  # @see Nonnative.proxy
  # @see Nonnative.proxies
  # @see Nonnative::Proxy
  # @see Nonnative::NoProxy
  class ProxyFactory
    class << self
      # Creates a proxy instance for the given runner configuration.
      #
      # @param service [Nonnative::ConfigurationRunner] runner configuration with an attached proxy configuration
      # @return [Nonnative::Proxy] proxy instance (may be a {Nonnative::NoProxy})
      def create(service)
        proxy = Nonnative.proxy(service.proxy.kind)

        proxy.new(service)
      end
    end
  end
end
