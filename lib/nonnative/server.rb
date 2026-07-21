# frozen_string_literal: true

module Nonnative
  # Runtime runner that manages an in-process Ruby server.
  #
  # A server runner:
  # - starts a Ruby thread that runs {#perform_start},
  # - waits briefly (via the runner `wait`), and
  # - participates in readiness/shutdown via TCP port checks orchestrated by {Nonnative::Pool}.
  #
  # Concrete server implementations are expected to subclass {Nonnative::Server} and implement:
  # - {#perform_start} (to bind/listen and begin serving), and
  # - {#perform_stop} (to gracefully shut down).
  #
  # {#stop} calls the stop hook once for every successfully constructed lifecycle, even if startup
  # never created a worker thread. This lets rollback release resources acquired by a constructor.
  #
  # The underlying configuration is a {Nonnative::ConfigurationServer}.
  #
  # @see Nonnative::ConfigurationServer
  # @see Nonnative::Pool
  class Server < Runner
    # @param service [Nonnative::ConfigurationServer] server configuration
    def initialize(service)
      super

      @timeout = Nonnative::Timeout.new(service.timeout)
      @cleanup_required = true
    end

    # Starts the server thread if it is not already running.
    #
    # A thread retained from a stop that exceeded its timeout is treated as not running, so a server
    # can be restarted even if a prior {#stop} never observed that thread's actual termination.
    #
    # @return [Array<(Integer, TrueClass)>]
    #   a tuple of:
    #   - a stable identifier for this server instance (`object_id`)
    #   - `true` (thread creation itself is considered started; readiness is checked separately)
    def start
      unless thread&.alive?
        @error = nil
        @cleanup_required = true
        @thread = Thread.new do
          perform_start
        rescue StandardError => e
          @error = e
          raise
        end
        @thread.report_on_exception = true

        wait_start

        Nonnative.logger.info "started server '#{service.name}'"
      end

      [object_id, true]
    end

    # Stops the server if its current lifecycle still requires cleanup.
    #
    # Calls {#perform_stop} even if startup never created a worker thread, then waits up to the
    # configured timeout for any owned thread to finish. A thread that exceeds the timeout is
    # terminated and reported through {Nonnative::Pool}. A later stop retries draining a retained
    # thread without calling {#perform_stop} again.
    #
    # @return [Integer, Array<(Integer, FalseClass)>] the server identifier when cleanup finishes, or
    #   the identifier and `false` when the owned thread exceeds the configured timeout
    def stop
      owned_thread = thread
      return object_id unless @cleanup_required || owned_thread

      perform_cleanup
      stopped = drain_thread(owned_thread) == :drained
      wait_stop
      @thread = nil unless owned_thread&.alive?

      Nonnative.logger.info "stopped server '#{service.name}'" if stopped

      stopped ? object_id : [object_id, false]
    end

    # Describes how the server thread terminated before becoming ready, for lifecycle diagnostics.
    #
    # Returns `nil` while the thread is still alive, so callers can distinguish a dead thread from a
    # live server that merely missed its readiness window.
    #
    # @return [String, nil] termination detail (clean early return or uncaught exception), or `nil`
    def termination
      return if thread.nil? || thread.alive?

      return "server thread raised #{error.class}: #{error.message}" if error

      'server thread exited before readiness'
    end

    private

    attr_reader :thread, :timeout, :error

    def perform_cleanup
      return unless @cleanup_required

      perform_stop
      @cleanup_required = false
    end

    def drain_thread(owned_thread)
      return :drained if owned_thread.nil? || !owned_thread.alive?
      return :drained if timeout.perform { owned_thread.join }

      owned_thread.terminate
      :timed_out
    end
  end
end
