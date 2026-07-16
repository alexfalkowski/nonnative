# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to fragment upstream responses.
  #
  # When active, client requests pass through unchanged, while each response written back to the
  # client is split into `proxy.options[:slice_size]`-byte writes, optionally separated by
  # `proxy.options[:slice_delay]` seconds, so a client that assumes one `recv` yields a whole protocol
  # frame is forced to perform multiple reads and reassemble the message. A missing or non-positive
  # `slice_size` leaves the connection in pass-through mode.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#slicer}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class SlicerSocketPair < SocketPair
    # Tracks the client socket so we can fragment only the response path.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      @local_socket = local_socket

      super
    ensure
      @local_socket = nil
    end

    # Writes response data to the client in configured slices, leaving requests unchanged.
    #
    # @param socket [IO] the socket to write to
    # @param data [String] the original payload
    # @return [Integer] number of bytes written
    def write(socket, data)
      return super unless socket.equal?(@local_socket)

      size = proxy.options[:slice_size]
      return super if size.nil? || size <= 0

      sliced_write(socket, data, size)
    end

    private

    # Writes `data` to `socket` in `size`-byte slices, sleeping `proxy.options[:slice_delay]` seconds
    # between slices (when positive) to help defeat TCP write coalescing.
    #
    # @param socket [IO] the socket to write to
    # @param data [String] the original payload
    # @param size [Integer] the slice size in bytes
    # @return [Integer] number of bytes written
    def sliced_write(socket, data, size)
      delay = proxy.options[:slice_delay]
      offset = 0
      written = 0

      while offset < data.bytesize
        chunk = data.byteslice(offset, size)
        written += socket.write(chunk)
        offset += chunk.bytesize

        sleep(delay) if delay&.positive? && offset < data.bytesize
      end

      written
    end
  end
end
