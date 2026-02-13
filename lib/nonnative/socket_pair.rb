# frozen_string_literal: true

module Nonnative
  # Base socket-pair implementation used by TCP proxies.
  #
  # A socket-pair connects an accepted local socket to a remote upstream socket and forwards bytes
  # in both directions until one side closes.
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
      remote_socket = create_remote_socket

      loop do
        ready = select([local_socket, remote_socket], nil, nil)

        break if pipe?(ready, local_socket, remote_socket)
        break if pipe?(ready, remote_socket, local_socket)
      end
    ensure
      Nonnative.logger.info "finished connect for local socket '#{local_socket.inspect}' and '#{remote_socket&.inspect}' for 'socket_pair'"

      local_socket.close
      remote_socket&.close
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

    # Pipes data from `socket1` to `socket2` if `socket1` is readable.
    #
    # @param ready [Array<Array<IO>>] the result from `select`
    # @param socket1 [IO] readable side
    # @param socket2 [IO] writable side
    # @return [Boolean] whether the piping loop should terminate
    def pipe?(ready, socket1, socket2)
      if ready[0].include?(socket1)
        data = read(socket1)
        return true if data.empty?

        write socket2, data
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
  end
end
