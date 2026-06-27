# frozen_string_literal: true

module Nonnative
  # No-op proxy implementation.
  #
  # This is the default proxy when `service.proxy.kind` is `"none"`.
  # It does not bind/listen or alter traffic; it simply exposes the service configuration's
  # client-facing `host` and `port`.
  #
  # Services can always call `start`, `stop`, and `reset` safely on this proxy.
  #
  # @see Nonnative.proxy
  # @see Nonnative::Proxy
  class NoProxy < Proxy
    # Starts the proxy.
    #
    # This implementation does nothing.
    #
    # @return [void]
    def start
      # Do nothing.
    end

    # Stops the proxy.
    #
    # This implementation does nothing.
    #
    # @return [void]
    def stop
      # Do nothing.
    end

    # Resets the proxy state.
    #
    # This implementation does nothing.
    #
    # @return [void]
    def reset
      # Do nothing.
    end

    # Returns the host clients should connect to.
    #
    # For {NoProxy}, this is the service configuration's client-facing `host`.
    #
    # @return [String]
    def host
      service.host
    end

    # Returns the port clients should connect to.
    #
    # For {NoProxy}, this is the service configuration's client-facing `port`.
    #
    # @return [Integer]
    def port
      service.port
    end
  end
end
