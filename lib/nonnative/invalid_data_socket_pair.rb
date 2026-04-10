# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate corrupted/incoherent traffic.
  #
  # When active, client requests still pass through unchanged, but responses flowing back from the
  # upstream socket are corrupted before they reach the client.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#invalid_data}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class InvalidDataSocketPair < SocketPair
    LINE_DELIMITERS = ["\r\n", "\n", "\r"].freeze

    # Track the accepted client socket so we can corrupt only the response path.
    def connect(local_socket)
      @local_socket = local_socket

      super
    ensure
      @local_socket = nil
    end

    # Writes corrupted data to the socket by mutating payload bytes.
    #
    # Client requests are forwarded unchanged so the upstream service can still parse them.
    # Responses flowing back to the client are corrupted in-place, which keeps line-based clients
    # from hanging while ensuring echoed data does not come back unchanged.
    #
    # @param socket [IO] the socket to write to
    # @param data [String] the original payload
    # @return [Integer] number of bytes written
    def write(socket, data)
      return super unless socket.equal?(@local_socket)

      super(socket, corrupt(data))
    end

    private

    def corrupt(data)
      # Preserve a final line ending so line-oriented clients still finish their reads.
      delimiter = LINE_DELIMITERS.find { |candidate| data.end_with?(candidate) } || ''
      payload = data.delete_suffix(delimiter)

      # A delimiter-only response still needs one byte we can corrupt without losing the terminator.
      payload = "\0" if payload.empty?

      # Flip the first byte so the payload is definitely wrong without mangling the whole
      # response structure and turning an invalid response into a timeout.
      payload.setbyte(0, payload.getbyte(0).zero? ? 1 : 0)

      "#{payload}#{delimiter}"
    end
  end
end
