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
  # - {#reset_peer}: reset connections immediately on accept (TCP RST rather than a graceful close)
  # - {#delay}: delay reads by a configured duration (default: 2 seconds)
  # - {#timeout}: accept connections and keep them silent until clients time out
  # - {#invalid_data}: forward requests unchanged and mutate upstream responses before they reach clients
  # - {#bandwidth}: throttle forwarded throughput to a configured rate (KB/s)
  # - {#limit_data}: forward a configured number of response bytes, then gracefully close
  # - {#slicer}: forward responses to the client in small writes to force multi-`recv` reassembly
  # - {#flaky}: fail a configurable fraction of new connections, forwarding the rest normally
  # - {#reset}: return to healthy pass-through behavior
  #
  # State changes terminate any active connections so new connections observe the new behavior.
  #
  # ## Wiring
  #
  # When enabled, your test/client should connect to the service `host` and `port` (the proxy
  # endpoint), and the proxy will forward traffic to the upstream target exposed by {#host}:{#port}.
  #
  # ## Configuration
  #
  # The proxy is configured via the service's `proxy` hash:
  #
  # - `kind`: `"fault_injection"`
  # - `host` / `port`: upstream target behind the proxy (exposed via {#host}/{#port})
  # - `log`: file path used by this proxy’s internal logger
  # - `wait`: sleep interval (seconds) applied after state changes
  # - `options`:
  #   - `delay`: delay duration in seconds used by {#delay}
  #   - `jitter`: optional random offset (seconds) added in `-jitter..jitter` to each `delay` (a
  #     negative value uses its magnitude), so clients see variable latency instead of a flat value
  #   - `rate`: positive throughput limit in KB/s used by {#bandwidth}; absent or non-positive
  #     values forward at full speed
  #   - `bytes`: positive response byte limit used by {#limit_data}; absent or non-positive values
  #     use pass-through behavior
  #   - `slice_size`: positive response slice size (bytes) used by {#slicer}; absent or non-positive
  #     values use pass-through behavior
  #   - `slice_delay`: optional delay (seconds) between slices used by {#slicer}
  #   - `probability`: connection failure fraction (0.0-1.0) used by {#flaky}; absent or non-positive
  #     values use pass-through behavior
  #
  # @see Nonnative::Proxy
  # @see Nonnative::SocketPairFactory
  class FaultInjectionProxy < Nonnative::Proxy
    # Used both to flush the accept-queue barrier and as the aggregate deadline for draining active
    # worker threads during stop.
    STOP_DRAIN_TIMEOUT = 1

    class Connection
      attr_accessor :pair, :thread
      attr_reader :socket

      def initialize(socket)
        @socket = socket
      end

      def close_sockets
        pair&.close
        socket.close unless socket.closed?
      end
    end

    # @param service [Nonnative::ConfigurationService] service configuration with proxy settings
    def initialize(service)
      @connections = Concurrent::Hash.new
      @logger = Logger.new(service.proxy.log)
      @mutex = Mutex.new
      @state = :none
      @stopping = false

      super
    end

    # Starts the proxy accept loop in a background thread.
    #
    # This binds a TCP server on the service `host` and `port`.
    # Clients connect to that service endpoint, while upstream traffic is forwarded to {#host}:{#port}.
    #
    # @return [void]
    def start
      mutex.synchronize { @stopping = false }
      logger
      @tcp_server = ::TCPServer.new(service.host, service.port)
      @thread = Thread.new { perform_start }

      Nonnative.logger.info "started with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
    end

    # Stops the proxy, closes active connections, and closes its listening socket.
    #
    # @return [void]
    def stop
      server = tcp_server
      mark_stopping
      drain_workers(close_connections)
      close_queued_connections(server)
      server&.close

      listener_thread = thread
      # Closing the server is meant to wake the blocked `accept`, but a concurrently blocked
      # `accept` is not reliably interrupted by `close` on every platform. Kill the listener so
      # `stop` cannot hang joining an accept loop that never woke (a no-op once it has exited).
      listener_thread&.kill
      listener_thread&.join

      @tcp_server = nil
      @thread = nil
      close_logger

      Nonnative.logger.info "stopped with host '#{service.host}' and port '#{service.port}' for proxy 'fault_injection'"
    end

    # Forces new connections to be closed immediately.
    #
    # @return [void]
    def close_all
      apply_state :close_all
    end

    # Forces new connections to be reset immediately.
    #
    # Unlike {#close_all}, which closes the socket gracefully (FIN), this closes the accepted socket
    # with a zero linger timeout so clients observe a TCP reset (`Errno::ECONNRESET`).
    #
    # @return [void]
    def reset_peer
      apply_state :reset_peer
    end

    # Delays reads before forwarding.
    #
    # The delay duration is controlled by `service.proxy.options[:delay]` and defaults to 2 seconds.
    #
    # @return [void]
    def delay
      apply_state :delay
    end

    # Accepts connections and stalls without forwarding bytes.
    #
    # This simulates a dependency that accepts a TCP connection but leaves clients waiting until
    # their own read timeout fires. The proxy keeps the connection silent until reset or stop closes
    # active connections.
    #
    # @return [void]
    def timeout
      apply_state :timeout
    end

    # Mutates upstream responses while forwarding client requests unchanged.
    #
    # @return [void]
    def invalid_data
      apply_state :invalid_data
    end

    # Throttles forwarded throughput to a configured rate.
    #
    # The rate is controlled by `service.proxy.options[:rate]` (kilobytes per second); when it is
    # absent or not positive the connection forwards at full speed.
    #
    # @return [void]
    def bandwidth
      apply_state :bandwidth
    end

    # Truncates the upstream byte stream after a configured number of bytes.
    #
    # Client requests are forwarded unchanged. The response byte limit is read from
    # `service.proxy.options[:bytes]`; when it is absent or not positive, the connection forwards at
    # full speed without truncation.
    #
    # @return [void]
    def limit_data
      apply_state :limit_data
    end

    # Fragments upstream responses into small writes before forwarding to the client.
    #
    # Client requests are forwarded unchanged. Each response is split into
    # `service.proxy.options[:slice_size]`-byte writes, optionally separated by
    # `service.proxy.options[:slice_delay]` seconds, so a client's `recv` returns a strict prefix of
    # the response rather than the whole message. When `slice_size` is absent or not positive, the
    # connection forwards at full speed without slicing.
    #
    # @return [void]
    def slicer
      apply_state :slicer
    end

    # Fails a configurable fraction of new connections while forwarding the rest normally.
    #
    # The fraction is controlled by `service.proxy.options[:probability]` (0.0-1.0); absent or
    # non-positive values behave like pass-through, and `1.0` fails every connection. Because each
    # connection decides independently, clients that retry/reconnect can observe both failures and
    # successes while this state stays active.
    #
    # @return [void]
    def flaky
      apply_state :flaky
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

    attr_reader :tcp_server, :thread, :connections, :mutex, :state, :stopping

    def perform_start
      loop do
        local_socket = tcp_server.accept
        id = local_socket.object_id
        unless register_connection(id, local_socket)
          local_socket.close
          next
        end
        Thread.start(local_socket) do |accepted_socket|
          accept_connection(id, accepted_socket) if register_connection_thread(id)
        end
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

      delete_connection(id)
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
      active_connections = mutex.synchronize do
        connections.to_a.tap { connections.clear }
      end

      active_connections.each do |id, connection|
        close_connection(id, connection)
      end

      active_connections.filter_map { |_id, connection| connection.thread }
    end

    def drain_workers(workers)
      deadline = monotonic_now + STOP_DRAIN_TIMEOUT
      workers.each do |worker|
        worker.join(remaining_time(deadline))
        terminate_worker(worker)
      end
    end

    def terminate_worker(worker)
      return unless worker.alive?

      worker.kill
      worker.join
    end

    def remaining_time(deadline) = [deadline - monotonic_now, 0].max

    def monotonic_now = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC)

    def close_queued_connections(server)
      return unless server

      # This connection is queued after every client that connected before shutdown began.
      # When the listener accepts and closes it, those earlier clients have been closed as well.
      barrier = TCPSocket.new(service.host, service.port)
      barrier.wait_readable(STOP_DRAIN_TIMEOUT)
    rescue IOError, SystemCallError
      nil
    ensure
      barrier&.close
    end

    def apply_state(state)
      Nonnative.logger.info "applying state '#{state}' for proxy 'fault_injection'"

      mutex.synchronize do
        return if @state == state

        @state = state
      end

      close_connections
      wait
    end

    def read_state = mutex.synchronize { state }

    def register_connection(id, socket)
      mutex.synchronize do
        return false if stopping

        connections[id] = Connection.new(socket)
        true
      end
    end

    def mark_stopping = mutex.synchronize { @stopping = true }

    def register_connection_thread(id)
      mutex.synchronize do
        connection = connections[id]
        return false unless connection && !stopping

        connection.thread = Thread.current
        true
      end
    end

    def attach_connection_pair(id, pair) = mutex.synchronize { connections[id]&.pair = pair }

    def delete_connection(id) = mutex.synchronize { connections.delete(id) }

    def close_connection(id, connection)
      Nonnative.logger.info "closing connection for '#{id}' for proxy 'fault_injection'"

      connection.close_sockets
    end

    def close_logger
      @logger&.close
    ensure
      @logger = nil
    end

    def logger = (@logger ||= Logger.new(service.proxy.log))
  end
end
