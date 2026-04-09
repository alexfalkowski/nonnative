# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate corrupted/incoherent traffic.
  #
  # When active, data written to the upstream socket is corrupted by shuffling the payload bytes
  # before forwarding.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#invalid_data}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class InvalidDataSocketPair < SocketPair
    # Writes corrupted data to the socket by shuffling bytes.
    #
    # The payload must always change, otherwise short or repetitive inputs such as "test" can
    # occasionally pass through unchanged and make fault-injection scenarios flaky.
    #
    # @param socket [IO] the socket to write to
    # @param data [String] the original payload
    # @return [Integer] number of bytes written
    def write(socket, data)
      Nonnative.logger.info "shuffling socket data '#{socket.inspect}' for 'invalid_data' pair"

      super(socket, corrupt(data))
    end

    private

    def corrupt(data)
      payload, delimiter = split_trailing_delimiter(data)
      return "\0#{delimiter}" if payload.empty?

      "#{corrupt_payload(payload)}#{delimiter}"
    end

    def split_trailing_delimiter(data)
      index = trailing_delimiter_start(data)
      payload = data.byteslice(0, index)
      delimiter = data.byteslice(index, data.bytesize - index) || ''

      [payload, delimiter]
    end

    def trailing_delimiter_start(data)
      index = data.bytesize

      while index.positive?
        byte = data.getbyte(index - 1)
        break unless [10, 13].include?(byte)

        index -= 1
      end

      index
    end

    def corrupt_payload(payload)
      bytes = payload.bytes
      corrupted = bytes.shuffle
      return corrupted.pack('C*') unless corrupted == bytes

      corrupted[0] = (corrupted[0] + 1) % 256
      corrupted.pack('C*')
    end
  end
end
