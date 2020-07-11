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

    def delay
      apply_state :delay
    end

    def invalid_data
      apply_state :invalid_data
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
        thread = Thread.start(tcp_server.accept) do |local_socket|
          SocketPairFactory.create(read_state, port).connect(local_socket)
          connections.delete(Thread.current.object_id)
        end
        thread.report_on_exception = false
        connections[thread.object_id] = thread
      end
    end

    def apply_state(state)
      mutex.synchronize { @state = state }
    end

    def read_state
      mutex.synchronize { state }
    end
  end
end
