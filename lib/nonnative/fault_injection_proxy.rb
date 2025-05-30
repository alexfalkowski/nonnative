# frozen_string_literal: true

module Nonnative
  class FaultInjectionProxy < Nonnative::Proxy
    def initialize(service)
      @connections = Concurrent::Hash.new
      @logger = Logger.new(service.proxy.log)
      @mutex = Mutex.new
      @state = :none

      super
    end

    def start
      @tcp_server = ::TCPServer.new(service.host, service.port)
      @thread = Thread.new { perform_start }

      Nonnative.logger.info "started with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
    end

    def stop
      thread&.terminate
      tcp_server&.close

      Nonnative.logger.info "stopped with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
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

    def host
      service.proxy.host
    end

    def port
      service.proxy.port
    end

    private

    attr_reader :tcp_server, :thread, :connections, :mutex, :state, :logger

    def perform_start
      loop do
        thread = Thread.start(tcp_server.accept) do |local_socket|
          id = Thread.current.object_id

          accept_connection id, local_socket
        end

        connections[thread.object_id] = thread
      end
    end

    def accept_connection(id, socket)
      error = connect(id, socket)
      if error
        logger.error "could not handle the connection for '#{id}' with socket '#{socket.inspect}' and error '#{error}'"
      else
        logger.info "handled connection for '#{id}' with socket '#{socket.inspect}'"
      end

      connections.delete(id)
    end

    def connect(id, socket)
      state = read_state
      Nonnative.logger.info "connecting for '#{id}' with socket '#{socket.inspect}' and state '#{state}' for proxy 'fault_injection'"

      pair = SocketPairFactory.create(state, service.proxy)
      pair.connect(socket)
    rescue StandardError => e
      socket.close

      e
    end

    def close_connections
      connections.each do |id, thread|
        Nonnative.logger.info "closing connection for '#{id}' for proxy 'fault_injection'"

        thread.terminate
      end

      connections.clear
    end

    def apply_state(state)
      mutex.synchronize do
        Nonnative.logger.info "applying state '#{state}' for proxy 'fault_injection'"

        return if @state == state

        @state = state
        close_connections

        wait
      end
    end

    def read_state
      mutex.synchronize { state }
    end
  end
end
