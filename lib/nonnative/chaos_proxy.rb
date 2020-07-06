# frozen_string_literal: true

module Nonnative
  class ChaosProxy < Nonnative::Proxy
    def initialize(service)
      @connections = Concurrent::Hash.new
      @mutex = Mutex.new
      @state = :none

      super service
    end

    def start
      @tcp_server = ::TCPServer.new('0.0.0.0', service.port)
      @thread = Thread.new { perform_start }
    end

    def stop
      thread.terminate
      tcp_server.close
    end

    def close_all
      apply_state :close_all
    end

    def reset
      apply_state :none
    end

    def port
      service.proxy.port
    end

    private

    attr_reader :tcp_server, :thread, :connections, :mutex, :state

    def perform_start
      loop do
        thread = Thread.start(tcp_server.accept) { |local_socket| connect(local_socket) }
        connections[thread.object_id] = thread
      end
    end

    def connect(local_socket)
      return local_socket.close if state?(:close_all)

      remote_socket = create_remote_socket
      return unless remote_socket

      loop do
        ready = select([local_socket, remote_socket], nil, nil)

        break if write(ready, local_socket, remote_socket)
        break if write(ready, remote_socket, local_socket)
      end
    rescue Errno::ECONNRESET
      # Just ignore it.
    ensure
      local_socket.close
      remote_socket&.close
      connections.delete(Thread.current.object_id)
    end

    def create_remote_socket
      timeout.perform do
        ::TCPSocket.new('0.0.0.0', port)
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

    def apply_state(state)
      mutex.synchronize { @state = state }
    end

    def state?(state)
      mutex.synchronize { @state == state }
    end
  end
end
