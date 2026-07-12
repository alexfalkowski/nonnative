# frozen_string_literal: true

module Nonnative
  # Runtime runner that manages an OS-level child process.
  #
  # A process runner:
  # - spawns a child process using the configured command and environment,
  # - waits briefly (via the runner `wait`), and
  # - participates in TCP readiness/shutdown checks plus optional HTTP/gRPC readiness probes
  #   orchestrated by {Nonnative::Pool}.
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

      # Retain the reaped status for this lifecycle so startup diagnostics can report it.
      status = ::Process.waitpid2(pid, ::Process::WNOHANG)
      @status = status&.last
      [pid, status.nil?]
    end

    # Stops the process if it is running.
    #
    # The process is signalled using the configured signal (defaults to `INT` when not set).
    # If it does not exit before the configured timeout, it is killed and the returned success value
    # is `false`; {Nonnative.stop} reports that outcome as a {Nonnative::StopError}.
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

    # Describes how the process terminated when it exited before becoming ready.
    #
    # Returns `nil` while the process is still running, so callers can distinguish an early exit
    # from a live process that merely missed its readiness window. The check is non-blocking and
    # reuses the status captured during {#start} when available.
    #
    # @return [String, nil] termination detail (exit status or terminating signal), or `nil`
    def termination
      status = captured_status
      return if status.nil?

      terminated_description(status)
    end

    protected

    def wait_stop
      timeout.perform do
        ::Process.waitpid2(pid)
      end
    end

    private

    attr_reader :pid, :timeout

    def captured_status
      return @status unless @status.nil?
      return if pid.nil?

      # A process that exited during the readiness window has not been reaped yet.
      @status = ::Process.waitpid2(pid, ::Process::WNOHANG)&.last
    rescue Errno::ECHILD, Errno::ESRCH
      nil
    end

    def terminated_description(status)
      return "process exited before readiness with exit status #{status.exitstatus}" if status.exited?
      return "process exited before readiness after being killed by signal #{signal_description(status.termsig)}" if status.signaled?

      "process exited before readiness (#{status})"
    end

    def signal_description(signal)
      name = Signal.signame(signal)
      name ? "SIG#{name} (#{signal})" : signal.to_s
    end

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
