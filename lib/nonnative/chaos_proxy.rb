# frozen_string_literal: true

module Nonnative
  class ChaosProxy < Nonnative::Proxy
    def initialize(service)
      @pool = RandomPort::Pool.new

      super service
    end

    def start
      @acquired_port = pool.acquire
      @tcp_server = ::TCPServer.new('0.0.0.0', service.port)
      @thread = Thread.new { perform_start }
    end

    def stop
      thread.terminate
      tcp_server.close
      pool.release(acquired_port)
    end

    def port
      acquired_port
    end

    private

    attr_reader :pool, :acquired_port, :tcp_server, :thread

    def perform_start
      loop do
        Thread.start(tcp_server.accept) { |local_socket| connect(local_socket) }
      end
    end

    def connect(local_socket)
      remote_socket = create_remote_socket
      return unless remote_socket

      loop do
        ready = select([local_socket, remote_socket], nil, nil)

        break if write(ready, local_socket, remote_socket)
        break if write(ready, remote_socket, local_socket)
      end
    ensure
      local_socket.close
      remote_socket&.close
    end

    def create_remote_socket
      timeout.perform do
        ::TCPSocket.new('0.0.0.0', acquired_port)
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        sleep 0.01
        retry
      end
    end

    def write(ready, socket1, socket2)
      if ready[0].include?(socket1)
        data = socket1.recv(1024)
        return true if data.empty?

        socket2.write(data)
      end

      false
    end
  end
end
