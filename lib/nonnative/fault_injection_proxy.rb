# frozen_string_literal: true

module Nonnative
  class FaultInjectionProxy < Nonnative::Proxy
    def initialize(service)
      @connections = Concurrent::Hash.new
      @logger = Logger.new(service.proxy.log)
      @mutex = Mutex.new
      @state = :none

      super service
    end

    def start
      @tcp_server = ::TCPServer.new(service.host, service.port)
      @thread = Thread.new { perform_start }
    end

    def stop
      thread&.terminate
      tcp_server&.close
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

    attr_reader :tcp_server, :thread, :connections, :mutex, :state, :logger

    def perform_start
      loop do
        thread = Thread.start(tcp_server.accept) do |local_socket|
          accept_connection local_socket
        end

        connections[thread.object_id] = thread
      end
    end

    def accept_connection(local_socket)
      id = Thread.current.object_id
      socket_info = local_socket.inspect

      error = connect(local_socket)
      if error
        logger.error "could not handle the connection for '#{id}' with socket '#{socket_info}' and error '#{error}'"
      else
        logger.info "handled connection for '#{id}' with socket '#{socket_info}'"
      end

      connections.delete(id)
    end

    def connect(local_socket)
      pair = SocketPairFactory.create(read_state, service.proxy)
      pair.connect(local_socket)
    rescue StandardError => e
      local_socket.close

      e
    end

    def close_connections
      connections.each_value(&:terminate)
      connections.clear
    end

    def apply_state(state)
      mutex.synchronize do
        @state = state
        close_connections
      end
    end

    def read_state
      mutex.synchronize { state }
    end
  end
end
