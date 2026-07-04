# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate read timeouts.
  #
  # When active, the proxy accepts the client connection and keeps it open without forwarding bytes.
  # Clients with read deadlines should observe their own timeout behavior.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#timeout}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  class TimeoutSocketPair < SocketPair
    # Keeps the accepted socket silent until reset or stop closes active proxy connections.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      @local_socket = local_socket

      Nonnative.logger.info "stalling socket '#{local_socket.inspect}' for 'timeout' pair"

      # Do not call super: the base implementation opens the upstream socket and forwards traffic.
      sleep 0.1 until local_socket.closed?
    ensure
      close
    end
  end
end
