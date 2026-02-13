# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate slow or stalled connections.
  #
  # When active, reads from the socket are delayed by a configured duration before being forwarded.
  #
  # The delay duration is controlled by `proxy.options[:delay]` and defaults to 2 seconds.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#delay}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class DelaySocketPair < SocketPair
    # Reads from the socket after sleeping for the configured delay duration.
    #
    # @param socket [IO] the socket to read from
    # @return [String] the bytes read from the socket
    def read(socket)
      Nonnative.logger.info "delaying socket '#{socket.inspect}' for 'delay' pair"

      duration = proxy.options[:delay] || 2
      sleep duration

      super
    end
  end
end
