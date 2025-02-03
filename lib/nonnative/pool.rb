# frozen_string_literal: true

module Nonnative
  class Pool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&)
      services.each(&:start)
      [servers, processes].each { |t| process(t, :start, :open?, &) }
    end

    def stop(&)
      [processes, servers].each { |t| process(t, :stop, :closed?, &) }
      services.each(&:stop)
    end

    def process_by_name(name)
      processes[runner_index(configuration.processes, name)].first
    end

    def server_by_name(name)
      servers[runner_index(configuration.servers, name)].first
    end

    def service_by_name(name)
      services[runner_index(configuration.services, name)]
    end

    def reset
      services.each { |s| s.proxy.reset }
      servers.each { |s| s.first.proxy.reset }
      processes.each { |p| p.first.proxy.reset }
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

    def services
      @services ||= configuration.services.map { |s| Nonnative::Service.new(s) }
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
