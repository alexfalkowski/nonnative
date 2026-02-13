# frozen_string_literal: true

module Nonnative
  # Orchestrates lifecycle for configured processes, servers and services.
  #
  # A pool is created when {Nonnative.start} is called and is accessible via {Nonnative.pool}.
  #
  # Lifecycle order is important:
  # - On start: services first, then servers/processes (in parallel port-check threads)
  # - On stop: processes/servers first, then services
  #
  # Readiness and shutdown are determined via TCP port checks ({Nonnative::Port#open?} / {Nonnative::Port#closed?}).
  #
  # @see Nonnative.start
  # @see Nonnative.stop
  # @see Nonnative::Port
  class Pool
    # @param configuration [Nonnative::Configuration] the configuration to run
    def initialize(configuration)
      @configuration = configuration
    end

    # Starts all configured runners and yields results for each process/server.
    #
    # Services are started first (proxy-only), then servers and processes are started and checked for readiness.
    #
    # @yieldparam name [String, nil] runner name
    # @yieldparam values [Object] runner-specific return value from `start` (e.g. `[pid, running]` for processes)
    # @yieldparam result [Boolean] result of the port readiness check (`true` if ready in time)
    # @return [void]
    def start(&)
      services.each(&:start)
      [servers, processes].each { |t| process(t, :start, :open?, &) }
    end

    # Stops all configured runners and yields results for each process/server.
    #
    # Processes and servers are stopped first and checked for shutdown, then services are stopped (proxy-only).
    #
    # @yieldparam name [String, nil] runner name
    # @yieldparam id [Object] runner-specific identifier returned by `stop` (e.g. pid or object_id)
    # @yieldparam result [Boolean] result of the port shutdown check (`true` if closed in time)
    # @return [void]
    def stop(&)
      [processes, servers].each { |t| process(t, :stop, :closed?, &) }
      services.each(&:stop)
    end

    # Finds a running process runner by configured name.
    #
    # @param name [String]
    # @return [Nonnative::Process]
    # @raise [Nonnative::NotFoundError] if no configured process matches the given name
    def process_by_name(name)
      processes[runner_index(configuration.processes, name)].first
    end

    # Finds a running server runner by configured name.
    #
    # @param name [String]
    # @return [Nonnative::Server]
    # @raise [Nonnative::NotFoundError] if no configured server matches the given name
    def server_by_name(name)
      servers[runner_index(configuration.servers, name)].first
    end

    # Finds a running service runner by configured name.
    #
    # @param name [String]
    # @return [Nonnative::Service]
    # @raise [Nonnative::NotFoundError] if no configured service matches the given name
    def service_by_name(name)
      services[runner_index(configuration.services, name)]
    end

    # Resets proxies for all runners in this pool.
    #
    # This is used by the Cucumber `@reset` hook and is safe to call any time after the pool is created.
    #
    # @return [void]
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
