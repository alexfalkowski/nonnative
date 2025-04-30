# frozen_string_literal: true

module Nonnative
  class SocketPair
    def initialize(proxy)
      @proxy = proxy
    end

    def connect(local_socket)
      remote_socket = create_remote_socket

      loop do
        ready = select([local_socket, remote_socket], nil, nil)

        break if pipe(ready, local_socket, remote_socket)
        break if pipe(ready, remote_socket, local_socket)
      end
    ensure
      Nonnative.logger.info "finished connect for local socket '#{local_socket.inspect}' and '#{remote_socket&.inspect}' for 'socket_pair'"

      local_socket.close
      remote_socket&.close
    end

    protected

    attr_reader :proxy

    def create_remote_socket
      ::TCPSocket.new(proxy.host, proxy.port)
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
      socket.recv(1024) || ''
    end

    def write(socket, data)
      socket.write(data)
    end
  end
end
