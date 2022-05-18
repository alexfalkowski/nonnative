# frozen_string_literal: true

module Nonnative
  class Process < Runner
    def initialize(service)
      super service

      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    def start
      unless exists?
        proxy.start
        @pid = spawn
        wait_start
      end

      pid
    end

    def stop
      if exists?
        kill
        proxy.stop
        wait_stop
      end

      pid
    end

    def memory
      return if pid.nil?

      @memory ||= GetProcessMem.new(pid)
    end

    def exists?
      return false if pid.nil?

      signal = Signal.list['EXIT']
      ::Process.kill(signal, pid)
      true
    rescue Errno::ESRCH
      false
    end

    def not_exists?
      !exists?
    end

    protected

    def wait_stop
      timeout.perform do
        ::Process.waitpid2(pid)
      end
    end

    private

    attr_reader :pid, :timeout

    def kill
      signal = Signal.list[service.signal || 'INT'] || Signal.list['INT']
      ::Process.kill(signal, pid)
    end

    def spawn
      environment = service.environment || {}
      environment = environment.transform_keys(&:to_s).transform_values(&:to_s)

      environment.each_key do |k|
        environment[k] = ENV.fetch(k, nil) || environment[k]
      end

      ::Kernel.spawn(environment, service.command.call, %i[out err] => [service.log, 'a'])
    end
  end
end
