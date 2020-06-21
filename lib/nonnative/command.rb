# frozen_string_literal: true

module Nonnative
  class Command < Nonnative::Service
    def initialize(service)
      @timeout = Nonnative::Timeout.new(service.timeout)

      super service
    end

    def start
      unless command_exists?
        @pid = command_spawn
        wait_start
      end

      pid
    end

    def stop
      if command_exists?
        command_kill
        wait_stop
      end

      pid
    end

    protected

    def wait_stop
      timeout.perform do
        Process.waitpid2(pid)
      end
    end

    private

    attr_reader :timeout, :pid

    def command_kill
      signal = Signal.list['INT']
      Process.kill(signal, pid)
    end

    def command_spawn
      spawn(service.command, %i[out err] => [service.file, 'a'])
    end

    def command_exists?
      return false if pid.nil?

      signal = Signal.list['EXIT']
      Process.kill(signal, pid)
      true
    rescue Errno::ESRCH
      false
    end
  end
end
