# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate slow or stalled connections.
  #
  # When active, reads from the socket are delayed by a configured duration before being forwarded.
  #
  # The delay duration is controlled by `proxy.options[:delay]` and defaults to 2 seconds. An
  # optional `proxy.options[:jitter]` (seconds) adds a random offset in `-jitter..jitter` to each
  # delay so clients see variable, tail-latency-like timing instead of a flat value; a negative
  # jitter uses its magnitude and the resulting delay is never negative. When `jitter` is absent the
  # delay is the flat duration.
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

      sleep delay_duration

      super
    end

    private

    # The delay applied before a read, optionally jittered by `proxy.options[:jitter]`.
    #
    # @return [Numeric] seconds to sleep (never negative)
    def delay_duration
      duration = proxy.options[:delay] || 2
      jitter = proxy.options[:jitter]&.abs
      return [duration, 0].max unless jitter

      [duration + rand(-jitter..jitter), 0].max
    end
  end
end
