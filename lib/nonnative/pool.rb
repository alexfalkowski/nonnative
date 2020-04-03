# frozen_string_literal: true

module Nonnative
  class Pool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&block)
      all = processes + servers
      process_all(all, :start, :open?, &block)
    end

    def stop(&block)
      all = processes + servers
      process_all(all, :stop, :closed?, &block)
    end

    private

    attr_reader :configuration

    def processes
      @processes ||= configuration.processes.map do |d|
        [Nonnative::Command.new(d), Nonnative::Port.new(d)]
      end
    end

    def servers
      @servers ||= configuration.servers.map do |d|
        [d.klass.new(d.port), Nonnative::Port.new(d)]
      end
    end

    def process_all(all, type_method, port_method, &block)
      types = []
      threads = []

      all.each do |type, port|
        types << type.send(type_method)
        threads << Thread.new { port.send(port_method) }
      end

      ThreadsWait.all_waits(*threads)

      ports = threads.map(&:value)

      yield_results(types, ports, &block)
    end

    def yield_results(types, ports)
      types.zip(ports).each do |id, result|
        yield id, result
      end
    end
  end
end
