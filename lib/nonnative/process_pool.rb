# frozen_string_literal: true

module Nonnative
  class ProcessPool
    def initialize(configuration)
      @configuration = configuration
    end

    def start
      processes.each do |p|
        result, pid = p.start

        yield result, pid
      end
    end

    def stop
      processes.each do |p|
        result, pid = p.stop

        yield result, pid
      end
    end

    private

    attr_reader :configuration

    def processes
      @processes ||= configuration.definitions.map { |d| Nonnative::Process.new(d) }
    end
  end
end
