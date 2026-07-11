# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to truncate upstream responses.
  #
  # When active, client requests pass through unchanged, while the first `proxy.options[:bytes]`
  # bytes of the upstream stream are forwarded to the client on each connection. Once the limit is
  # reached, the pair's normal connection lifecycle closes both sockets gracefully. A missing or
  # non-positive limit leaves the connection in pass-through mode.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#limit_data}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class LimitDataSocketPair < SocketPair
    # Tracks the client socket and response byte budget for this connection.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      @local_socket = local_socket
      @remaining = proxy.options[:bytes]
      @limit_reached = false

      super
    ensure
      @local_socket = nil
      @remaining = nil
      @limit_reached = nil
    end

    protected

    # Stops the base forwarding loop after the response budget has been written.
    #
    # @param ready [Array<Array<IO>>] the result from `select`
    # @param source_socket [IO] readable side
    # @param destination_socket [IO] writable side
    # @return [Boolean] whether the forwarding loop should terminate
    def pipe?(ready, source_socket, destination_socket)
      return true if @limit_reached

      super || @limit_reached
    end

    # Limits writes to the client while leaving writes to the upstream unchanged.
    #
    # @param socket [IO] the socket to write to
    # @param data [String] the original payload
    # @return [Integer] number of bytes written
    def write(socket, data)
      return super unless socket.equal?(@local_socket)
      return super if @remaining.nil? || @remaining <= 0

      data = data.byteslice(0, @remaining)
      @remaining -= data.bytesize
      @limit_reached = @remaining.zero?

      super
    end
  end
end
