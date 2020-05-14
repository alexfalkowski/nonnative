# frozen_string_literal: true

module Nonnative
  class Command
    def initialize(process)
      @process = process
      @started = false
    end

    def name
      process.command
    end

    def start
      unless started
        @pid = spawn(process.command, %i[out err] => [process.file, 'a'])
        @started = true

        sleep 0.1 # Processes take time to start
      end

      pid
    end

    def stop
      raise Nonnative::Error, "Can't stop a process that has not started" unless started

      ::Process.kill('SIGINT', pid)
      @started = false

      sleep 0.1 # Processes take time to stop

      pid
    end

    private

    attr_reader :process, :pid, :started
  end
end
