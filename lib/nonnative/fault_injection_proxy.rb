# frozen_string_literal: true

module Nonnative
  # Fault-injection proxy for TCP services.
  #
  # This proxy accepts incoming TCP connections and forwards traffic to the configured upstream
  # (`service.proxy.host` / `service.proxy.port`) via a socket-pair implementation. It can also inject
  # failures to help validate client resilience.
  #
  # This class exposes a small public control surface for tests:
  #
  # - {#close_all}: close connections immediately on accept
  # - {#delay}: delay reads by a configured duration (default: 2 seconds)
  # - {#invalid_data}: corrupt outbound data by shuffling characters
  # - {#reset}: return to healthy pass-through behavior
  #
  # State changes terminate any active connections so new connections observe the new behavior.
  #
  # ## Wiring
  #
  # When enabled, your test/client should connect to the runner `host` / `port` (the proxy endpoint),
  # and the proxy will forward traffic to the upstream target exposed by {#host}:{#port}.
  #
  # ## Configuration
  #
  # The proxy is configured via the runner’s `proxy` hash:
  #
  # - `kind`: `"fault_injection"`
  # - `host` / `port`: upstream target behind the proxy (exposed via {#host}/{#port})
  # - `log`: file path used by this proxy’s internal logger
  # - `wait`: sleep interval (seconds) applied after state changes
  # - `options`:
  #   - `delay`: delay duration in seconds used by {#delay}
  #
  # @see Nonnative::Proxy
  # @see Nonnative::SocketPairFactory
  class FaultInjectionProxy < Nonnative::Proxy
    class Connection
      attr_accessor :pair, :thread
      attr_reader :socket

      def initialize(socket)
        @socket = socket
      end

      def close
        pair&.close
        socket.close unless socket.closed?
        thread&.terminate
      end
    end

    # @param service [Nonnative::ConfigurationRunner] runner configuration with proxy settings
    def initialize(service)
      @connections = Concurrent::Hash.new
      @logger = Logger.new(service.proxy.log)
      @mutex = Mutex.new
      @state = :none

      super
    end

    # Starts the proxy accept loop in a background thread.
    #
    # This binds a TCP server on the underlying runner’s `service.host` / `service.port`.
    # Clients connect to that runner endpoint, while upstream traffic is forwarded to {#host}:{#port}.
    #
    # @return [void]
    def start
      @tcp_server = ::TCPServer.new(service.host, service.port)
      @thread = Thread.new { perform_start }

      Nonnative.logger.info "started with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
    end

    # Stops the proxy, closes active connections, and closes its listening socket.
    #
    # @return [void]
    def stop
      mutex.synchronize do
        close_connections
      end

      server = @tcp_server
      @tcp_server = nil
      server&.close

      listener_thread = @thread
      @thread = nil
      listener_thread&.join

      Nonnative.logger.info "stopped with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
    end

    # Forces new connections to be closed immediately.
    #
    # @return [void]
    def close_all
      apply_state :close_all
    end

    # Delays reads before forwarding.
    #
    # The delay duration is controlled by `service.proxy.options[:delay]` and defaults to 2 seconds.
    #
    # @return [void]
    def delay
      apply_state :delay
    end

    # Corrupts forwarded data by shuffling characters.
    #
    # @return [void]
    def invalid_data
      apply_state :invalid_data
    end

    # Resets the proxy back to healthy pass-through behavior.
    #
    # @return [void]
    def reset
      apply_state :none
    end

    # Returns the upstream host behind this proxy.
    #
    # @return [String]
    def host
      service.proxy.host
    end

    # Returns the upstream port behind this proxy.
    #
    # @return [Integer]
    def port
      service.proxy.port
    end

    private

    attr_reader :tcp_server, :thread, :connections, :mutex, :state, :logger

    def perform_start
      loop do
        local_socket = tcp_server.accept
        id = local_socket.object_id
        register_connection(id, local_socket)
        connection_thread = Thread.start(local_socket) do |accepted_socket|
          accept_connection id, accepted_socket
        end
        attach_connection_thread(id, connection_thread)
      end
    rescue IOError, Errno::EBADF
      nil
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
      attach_connection_pair(id, pair)
      pair.connect(socket)
    rescue StandardError => e
      socket.close

      e
    end

    def close_connections
      connections.each do |id, connection|
        close_connection(id, connection)
      end
    ensure
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

    def register_connection(id, socket)
      connections[id] = Connection.new(socket)
    end

    def attach_connection_thread(id, thread)
      connections[id]&.thread = thread
    end

    def attach_connection_pair(id, pair)
      connections[id]&.pair = pair
    end

    def close_connection(id, connection)
      Nonnative.logger.info "closing connection for '#{id}' for proxy 'fault_injection'"

      connection.close
    end
  end
end
