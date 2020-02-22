# frozen_string_literal: true

module Nonnative
  class Process
    def initialize(definition)
      @definition = definition
      @started = false
    end

    def start
      unless started
        @pid = spawn(definition.process, %i[out err] => [definition.file, 'a'])
        @started = true
      end

      pid
    end

    def stop
      raise Nonnative::Error, "Can't stop a process that has not started" unless started

      ::Process.kill('SIGINT', pid)
      @started = false

      pid
    end

    private

    attr_reader :definition, :pid, :started
  end
end
