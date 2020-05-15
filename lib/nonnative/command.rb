# frozen_string_literal: true

module Nonnative
  class Command < Nonnative::Service
    def initialize(process)
      @process = process
    end

    def name
      process.command
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

    private

    attr_reader :process, :pid, :started

    def command_kill
      ::Process.kill('SIGINT', pid)
    end

    def command_spawn
      spawn(process.command, %i[out err] => [process.file, 'a'])
    end

    def command_exists?
      return false if pid.nil?

      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    end
  end
end
