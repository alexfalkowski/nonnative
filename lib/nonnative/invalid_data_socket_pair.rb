# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate corrupted/incoherent traffic.
  #
  # When active, data written to the upstream socket is corrupted by shuffling the characters in the
  # payload before forwarding.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#invalid_data}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class InvalidDataSocketPair < SocketPair
    # Writes corrupted data to the socket by shuffling characters.
    #
    # @param socket [IO] the socket to write to
    # @param data [String] the original payload
    # @return [Integer] number of bytes written
    def write(socket, data)
      Nonnative.logger.info "shuffling socket data '#{socket.inspect}' for 'invalid_data' pair"

      data = data.chars.shuffle.join

      super
    end
  end
end
