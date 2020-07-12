# frozen_string_literal: true

module Nonnative
  class SocketPair
    def initialize(proxy, logger)
      @proxy = proxy
      @logger = logger
    end

    def connect(local_socket)
      remote_socket = create_remote_socket

      loop do
        ready = select([local_socket, remote_socket], nil, nil)

        break if pipe(ready, local_socket, remote_socket)
        break if pipe(ready, remote_socket, local_socket)
      end
    rescue StandardError => e
      logger.error e
    ensure
      local_socket.close
      remote_socket&.close
    end

    protected

    attr_reader :proxy, :logger

    def create_remote_socket
      ::TCPSocket.new('0.0.0.0', proxy.port)
    end

    def pipe(ready, socket1, socket2)
      if ready[0].include?(socket1)
        data = read(socket1)
        return true if data.empty?

        write socket2, data
      end

      false
    end

    def read(socket)
      socket.recv(1024)
    end

    def write(socket, data)
      socket.write(data)
    end
  end
end
