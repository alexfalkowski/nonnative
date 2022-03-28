# frozen_string_literal: true

module Nonnative
  class Process < Runner
    def initialize(service)
      super service

      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    def start
      unless process_exists?
        proxy.start
        @pid = process_spawn
        wait_start
      end

      pid
    end

    def stop
      if process_exists?
        process_kill
        proxy.stop
        wait_stop
      end

      pid
    end

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
      environment = service.environment || {}
      environment = environment.transform_keys(&:to_s).transform_values(&:to_s)

      environment.each do |k, v|
        environment[k] = ENV[k] || environment[v]
      end

      spawn(environment, service.command, %i[out err] => [service.log, 'a'])
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
