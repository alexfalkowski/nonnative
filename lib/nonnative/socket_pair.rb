# frozen_string_literal: true

module Nonnative
  # Base socket-pair implementation used by TCP proxies.
  #
  # A socket-pair connects an accepted local socket to a remote upstream socket and forwards bytes
  # in both directions. When one direction reaches EOF (for example a client that half-closes its
  # write side after sending a request), the paired write side is closed and the other direction
  # keeps forwarding until it too ends, so an in-flight response is delivered rather than dropped.
  #
  # This is used by {Nonnative::FaultInjectionProxy} to implement pass-through forwarding, and is
  # subclassed to inject failures (close immediately, delay reads, corrupt writes, etc).
  #
  # The `proxy` argument is expected to provide `host` and `port` for the upstream connection
  # (typically a {Nonnative::ConfigurationProxy}).
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPairFactory
  # @see Nonnative::CloseAllSocketPair
  # @see Nonnative::DelaySocketPair
  # @see Nonnative::TimeoutSocketPair
  # @see Nonnative::InvalidDataSocketPair
  class SocketPair
    # @param proxy [#host, #port, #options] proxy configuration used to connect upstream
    def initialize(proxy)
      @proxy = proxy
    end

    # Connects the given local socket to an upstream socket and pipes data until the connection ends.
    #
    # @param local_socket [TCPSocket] the accepted client socket
    # @return [void]
    def connect(local_socket)
      @local_socket = local_socket
      @remote_socket = create_remote_socket
      @open = [@local_socket, @remote_socket]

      loop do
        ready = select(@open, nil, nil)

        break if pipe?(ready, @local_socket, @remote_socket)
        break if pipe?(ready, @remote_socket, @local_socket)
        break if @open.empty?
      end
    ensure
      Nonnative.logger.info "finished connect for local socket '#{@local_socket.inspect}' and '#{@remote_socket&.inspect}' for 'socket_pair'"

      close
    end

    # Closes any open sockets managed by this pair.
    #
    # @return [void]
    def close
      close_socket @local_socket
      close_socket @remote_socket
    end

    protected

    # Returns the proxy configuration.
    #
    # @return [Object]
    attr_reader :proxy

    # Creates the upstream socket connection.
    #
    # @return [TCPSocket]
    def create_remote_socket
      ::TCPSocket.new(proxy.host, proxy.port)
    end

    # Pipes data from `source_socket` to `destination_socket` when the source is readable.
    #
    # On EOF the source is half-closed rather than terminating the whole connection: the destination
    # write side is closed and the source is removed from the forwarding set, so the opposite
    # direction keeps forwarding until it also ends.
    #
    # @param ready [Array<Array<IO>>] the result from `select`
    # @param source_socket [IO] readable side
    # @param destination_socket [IO] writable side
    # @return [Boolean] whether the piping loop should terminate
    def pipe?(ready, source_socket, destination_socket)
      if ready[0].include?(source_socket)
        data = read(source_socket)
        return half_close(source_socket, destination_socket) if data.empty?

        write destination_socket, data
      end

      false
    end

    # Reads bytes from the given socket.
    #
    # Subclasses can override this to inject behavior (e.g. delay).
    #
    # @param socket [IO]
    # @return [String]
    def read(socket)
      socket.recv(1024) || ''
    end

    # Writes bytes to the given socket.
    #
    # Subclasses can override this to inject behavior (e.g. corrupt data).
    #
    # @param socket [IO]
    # @param data [String]
    # @return [Integer] number of bytes written
    def write(socket, data)
      socket.write(data)
    end

    # Half-closes one direction after its source reaches EOF: closes the destination write side and
    # removes the source from the forwarding set, so the opposite direction keeps forwarding.
    #
    # @param source_socket [IO] the side that reached EOF
    # @param destination_socket [IO] the paired side whose write half is closed
    # @return [false] so the forwarding loop continues until both directions have ended
    def half_close(source_socket, destination_socket)
      @open.delete(source_socket)
      destination_socket.close_write

      false
    rescue IOError, SystemCallError
      false
    end

    def close_socket(socket)
      return if socket.nil? || socket.closed?

      socket.close
    rescue IOError
      nil
    end
  end
end
