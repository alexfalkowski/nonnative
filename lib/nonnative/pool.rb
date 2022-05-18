# frozen_string_literal: true

module Nonnative
  class Pool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&block)
      services.each(&:start)
      [servers, processes].each { |t| process(t, :start, %i[exists? open?], &block) }
    end

    def stop(&block)
      [processes, servers].each { |t| process(t, :stop, %i[not_exists? closed?], &block) }
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

    private

    attr_reader :configuration

    def runner_index(runners, name)
      index = runners.find_index { |s| s.name == name }
      raise NotFoundError, "Could not find runner with name '#{name}'" if index.nil?

      index
    end

    def processes
      @processes ||= configuration.processes.map { |p| [Nonnative::Process.new(p), Nonnative::Port.new(p)] }
    end

    def servers
      @servers ||= configuration.servers.map { |s| [s.klass.new(s), Nonnative::Port.new(s)] }
    end

    def services
      @services ||= configuration.services.map { |s| Nonnative::Service.new(s) }
    end

    def process(all, type_method, verifier_methods, &block)
      types = []
      pids = []
      threads = []

      all.each do |type, port|
        types << type
        pids << type.send(type_method)
        threads << Thread.new { type.send(verifier_methods[0]) && port.send(verifier_methods[1]) }
      end

      verifications = threads.map(&:value)

      yield_results(types, pids, verifications, &block)
    end

    def yield_results(all, pids, verifications)
      all.zip(pids, verifications).each do |type, id, result|
        yield type.name, id, result
      end
    end
  end
end
