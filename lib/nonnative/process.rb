# frozen_string_literal: true

module Nonnative
  # Runtime runner that manages an OS-level child process.
  #
  # A process runner:
  # - spawns a child process using the configured command and environment,
  # - waits briefly (via the runner `wait`), and
  # - participates in readiness/shutdown via TCP port checks orchestrated by {Nonnative::Pool}.
  #
  # The underlying configuration is a {Nonnative::ConfigurationProcess}.
  #
  # @see Nonnative::ConfigurationProcess
  # @see Nonnative::Pool
  class Process < Runner
    # @param service [Nonnative::ConfigurationProcess] process configuration
    def initialize(service)
      super

      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    # @return [GetProcessMem, nil] memory reader for the current process lifecycle
    attr_reader :memory

    # Spawns the configured process if it is not already running.
    #
    # @return [Array<(Integer, Boolean)>]
    #   a tuple of:
    #   - the spawned process id (pid)
    #   - whether the process appears to still be running (non-blocking wait result)
    def start
      unless process_exists?
        @pid = process_spawn
        # Keep memory reads bound to the child spawned for this lifecycle.
        @memory = GetProcessMem.new(pid)
        wait_start
      end

      [pid, ::Process.waitpid2(pid, ::Process::WNOHANG).nil?]
    end

    # Stops the process if it is running.
    #
    # The process is signalled using the configured signal (defaults to `INT` when not set).
    #
    # @return [Array<(Integer, Boolean)>]
    #   a tuple of:
    #   - the pid that was stopped (or `nil` if the process was never started)
    #   - whether the process exited before the configured timeout
    def stop
      stopped = true

      if process_exists?
        process_kill
        stopped = wait_stop != false
        force_stop unless stopped
      end

      [pid, stopped]
    ensure
      @memory = nil
    end

    protected

    def wait_stop
      timeout.perform do
        ::Process.waitpid2(pid)
      end
    end

    private

    attr_reader :pid, :timeout

    def process_kill
      signal = Signal.list[service.signal || 'INT'] || Signal.list['INT']
      ::Process.kill(signal, pid)
    end

    def force_stop
      ::Process.kill('KILL', pid)
      wait_stop
    rescue Errno::ESRCH, Errno::ECHILD
      true
    end

    def process_spawn
      environment = service.environment.to_h
      environment = environment.transform_keys(&:to_s).transform_values(&:to_s)

      command = Array(service.command.call)

      spawn(environment, *command, %i[out err] => [service.log, 'a']).tap do |pid|
        Nonnative.logger.info "started '#{command.join(' ')}' with pid '#{pid}'"
      end
    end

    def process_exists?
      return false if pid.nil?

      signal = Signal.list['EXIT']
      ::Process.kill(signal, pid)
      true
    rescue Errno::ESRCH
      false
    end
  end
end
