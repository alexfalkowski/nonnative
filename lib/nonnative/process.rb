# frozen_string_literal: true

module Nonnative
  # Runtime runner that manages an OS-level child process.
  #
  # A process runner:
  # - starts the configured proxy (if any),
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

    # Starts the proxy (if any) and spawns the configured process if it is not already running.
    #
    # @return [Array<(Integer, Boolean)>]
    #   a tuple of:
    #   - the spawned process id (pid)
    #   - whether the process appears to still be running (non-blocking wait result)
    def start
      unless process_exists?
        proxy.start
        @pid = process_spawn
        wait_start
      end

      [pid, ::Process.waitpid2(pid, ::Process::WNOHANG).nil?]
    end

    # Stops the process (if running) and stops the proxy (if any).
    #
    # The process is signalled using the configured signal (defaults to `INT` when not set).
    #
    # @return [Integer, nil] the pid that was stopped (or `nil` if the process was never started)
    def stop
      if process_exists?
        process_kill
        proxy.stop
        wait_stop
      end

      pid
    end

    # Returns a memoized memory reader for the spawned process.
    #
    # This is primarily used by acceptance tests to assert memory usage.
    #
    # @return [GetProcessMem, nil] a memory reader for the pid, or `nil` if not started
    def memory
      return if pid.nil?

      @memory ||= GetProcessMem.new(pid)
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

    def process_spawn
      environment = service.environment.to_h
      environment = environment.transform_keys(&:to_s).transform_values(&:to_s)

      environment.each_key do |k|
        environment[k] = ENV.fetch(k, nil) || environment[k]
      end

      command = service.command.call

      spawn(environment, command, %i[out err] => [service.log, 'a']).tap do |pid|
        Nonnative.logger.info "started '#{command}' with pid '#{pid}'"
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
