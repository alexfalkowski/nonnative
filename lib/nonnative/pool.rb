# frozen_string_literal: true

module Nonnative
  class Pool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&block)
      [servers, processes].each { |t| process(t, :start, :open?, &block) }
    end

    def stop(&block)
      [processes, servers].each { |t| process(t, :stop, :closed?, &block) }
    end

    def process_by_name(name)
      processes[runner_index(configuration.processes, name)].first
    end

    def server_by_name(name)
      servers[runner_index(configuration.servers, name)].first
    end

    private

    attr_reader :configuration

    def runner_index(runners, name)
      index = runners.find_index { |s| s.name == name }
      raise NotFoundError, "Could not find runner with name '#{name}'" if index.nil?

      index
    end

    def processes
      @processes ||= configuration.processes.map do |p|
        [Nonnative::Process.new(p), Nonnative::Port.new(p)]
      end
    end

    def servers
      @servers ||= configuration.servers.map do |s|
        [s.klass.new(s), Nonnative::Port.new(s)]
      end
    end

    def process(all, type_method, port_method, &)
      types = []
      pids = []
      threads = []

      all.each do |type, port|
        types << type
        pids << type.send(type_method)
        threads << Thread.new { port.send(port_method) }
      end

      ports = threads.map(&:value)

      yield_results(types, pids, ports, &)
    end

    def yield_results(all, pids, ports)
      all.zip(pids, ports).each do |type, values, result|
        yield type.name, values, result
      end
    end
  end
end
