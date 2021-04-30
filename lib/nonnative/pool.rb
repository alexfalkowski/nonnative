# frozen_string_literal: true

module Nonnative
  class Pool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&block)
      services.each(&:start)
      [servers, processes].each { |t| process(t, :start, :open?, &block) }
    end

    def stop(&block)
      [processes, servers].each { |t| process(t, :stop, :closed?, &block) }
      services.each(&:stop)
    end

    def process_by_name(name)
      index = configuration.processes.find_index { |s| s.name == name }
      processes[index].first
    end

    def server_by_name(name)
      index = configuration.servers.find_index { |s| s.name == name }
      servers[index].first
    end

    def service_by_name(name)
      index = configuration.services.find_index { |s| s.name == name }
      services[index]
    end

    private

    attr_reader :configuration

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

    def services
      @services ||= configuration.services.map { |s| Nonnative::Service.new(s) }
    end

    def process(all, type_method, port_method, &block)
      types = []
      pids = []
      threads = []

      all.each do |type, port|
        types << type
        pids << type.send(type_method)
        threads << Thread.new { port.send(port_method) }
      end

      ports = threads.map(&:value)

      yield_results(types, pids, ports, &block)
    end

    def yield_results(all, pids, ports)
      all.zip(pids, ports).each do |type, id, result|
        yield type.name, id, result
      end
    end
  end
end
