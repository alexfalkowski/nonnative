# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate a bandwidth-limited link.
  #
  # When active, each forwarded read is throttled so throughput does not exceed
  # `proxy.options[:rate]` kilobytes per second (1 KB = 1024 bytes), by sleeping in proportion to the
  # bytes read. Both directions are throttled, so a client under test sees a slow-but-alive
  # dependency. When `rate` is absent or not positive the connection forwards at full speed.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#bandwidth}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class BandwidthSocketPair < SocketPair
    # One kilobyte in bytes; `proxy.options[:rate]` is expressed in KB/s.
    KILOBYTE = 1024

    # Reads from the socket, then sleeps so the forwarded throughput stays within the configured rate.
    #
    # @param socket [IO] the socket to read from
    # @return [String] the bytes read from the socket
    def read(socket)
      super.tap { |data| throttle(data.bytesize) }
    end

    private

    # Sleeps in proportion to the bytes read so throughput does not exceed `rate` KB/s. A missing or
    # non-positive rate (or an empty read) forwards at full speed.
    #
    # @param bytes [Integer] the number of bytes just read
    # @return [void]
    def throttle(bytes)
      rate = proxy.options[:rate]
      return if rate.nil? || rate <= 0 || bytes.zero?

      sleep(bytes / (rate * KILOBYTE.to_f))
    end
  end
end
