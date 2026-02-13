# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate immediate connection failure.
  #
  # When active, the proxy accepts a TCP connection and closes it immediately without forwarding any
  # bytes to the upstream service.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#close_all}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class CloseAllSocketPair < SocketPair
    # Closes the accepted socket immediately.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      Nonnative.logger.info "closing socket '#{local_socket.inspect}' for 'close_all' pair"

      local_socket.close
    end
  end
end
