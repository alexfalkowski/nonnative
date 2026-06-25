# frozen_string_literal: true

module Nonnative
  # Factory for creating proxy instances for services.
  #
  # A runtime service constructs a proxy via this factory. The proxy implementation is selected by
  # `service.proxy.kind` and resolved using {Nonnative.proxy}.
  #
  # If the kind is `"none"`, {Nonnative.proxy} returns {Nonnative::NoProxy}.
  # Unknown non-`"none"` kinds raise an error so proxy configuration typos do not silently disable
  # fault injection.
  #
  # @see Nonnative.proxy
  # @see Nonnative.proxies
  # @see Nonnative::Proxy
  # @see Nonnative::NoProxy
  class ProxyFactory
    class << self
      # Creates a proxy instance for the given service configuration.
      #
      # @param service [Nonnative::ConfigurationService] service configuration with an attached proxy configuration
      # @return [Nonnative::Proxy] proxy instance (may be a {Nonnative::NoProxy})
      def create(service)
        proxy = Nonnative.proxy(service.proxy.kind)

        proxy.new(service)
      end
    end
  end
end
