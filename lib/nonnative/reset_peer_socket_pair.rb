# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate an abrupt connection reset.
  #
  # When active, the proxy accepts a TCP connection and closes it with a zero linger timeout, so the
  # kernel sends a TCP RST instead of a graceful FIN. Clients observe a reset ("connection reset by
  # peer", `Errno::ECONNRESET`) rather than a clean end-of-stream, which is distinct from the graceful
  # close performed by {Nonnative::CloseAllSocketPair}.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#reset_peer}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  # @see Nonnative::CloseAllSocketPair
  class ResetPeerSocketPair < SocketPair
    # Resets the accepted socket by closing it with a zero linger timeout, forcing a TCP RST.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      Nonnative.logger.info "resetting socket '#{local_socket.inspect}' for 'reset_peer' pair"

      local_socket.setsockopt(Socket::Option.linger(true, 0))
      local_socket.close
    end
  end
end
