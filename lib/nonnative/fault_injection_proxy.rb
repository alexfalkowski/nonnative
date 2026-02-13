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
  # When enabled, your test/client should typically connect to {#host}:{#port} (the proxy endpoint),
  # and the proxy will connect onward to the underlying service.
  #
  # ## Configuration
  #
  # The proxy is configured via the runner’s `proxy` hash:
  #
  # - `kind`: `"fault_injection"`
  # - `host` / `port`: where the proxy should be reached by clients (exposed via {#host}/{#port})
  # - `log`: file path used by this proxy’s internal logger
  # - `wait`: sleep interval (seconds) applied after state changes
  # - `options`:
  #   - `delay`: delay duration in seconds used by {#delay}
  #
  # @see Nonnative::Proxy
  # @see Nonnative::SocketPairFactory
  class FaultInjectionProxy < Nonnative::Proxy
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
    # Clients should connect to {#host}:{#port}.
    #
    # @return [void]
    def start
      @tcp_server = ::TCPServer.new(service.host, service.port)
      @thread = Thread.new { perform_start }

      Nonnative.logger.info "started with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
    end

    # Stops the proxy and closes its listening socket.
    #
    # @return [void]
    def stop
      thread&.terminate
      tcp_server&.close

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

    # Returns the host clients should connect to when using this proxy.
    #
    # @return [String]
    def host
      service.proxy.host
    end

    # Returns the port clients should connect to when using this proxy.
    #
    # @return [Integer]
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
