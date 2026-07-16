# frozen_string_literal: true

module Nonnative
  # Socket-pair variant used by the fault-injection proxy to simulate a flapping dependency.
  #
  # When active, each new connection independently fails with probability
  # `proxy.options[:probability]` (closed immediately, like {Nonnative::CloseAllSocketPair}) and
  # otherwise forwards normally. Because the decision is made per connection rather than per state, a
  # client that retries/reconnects can observe some attempts fail and others succeed while this fault
  # state stays active, exercising retry/reconnect/circuit-breaker recovery rather than a fully down
  # dependency. A missing or non-positive `probability` behaves like pass-through; `probability >= 1.0`
  # fails every connection.
  #
  # This behavior is enabled by calling {Nonnative::FaultInjectionProxy#flaky}.
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::SocketPair
  # @see Nonnative::CloseAllSocketPair
  class FlakySocketPair < SocketPair
    # Fails the connection with the configured probability, otherwise forwards it normally.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      return super unless fail?

      Nonnative.logger.info "closing socket '#{local_socket.inspect}' for 'flaky' pair"

      local_socket.close
    end

    private

    # Decides whether this connection should fail, based on `proxy.options[:probability]`.
    #
    # @return [Boolean]
    def fail?
      probability = proxy.options[:probability]
      return false if probability.nil? || probability <= 0

      rand < probability
    end
  end
end
