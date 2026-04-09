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
      @services = nil
      @servers = nil
      @processes = nil
    end

    # Starts all configured runners and yields results for each process/server.
    #
    # Services are started first (proxy-only), then servers and processes are started and checked for readiness.
    #
    # @yieldparam name [String, nil] runner name
    # @yieldparam values [Object] runner-specific return value from `start` (e.g. `[pid, running]` for processes)
    # @yieldparam result [Boolean] result of the port readiness check (`true` if ready in time)
    # @return [Array<String>] lifecycle and readiness-check errors collected while starting
    def start(&)
      errors = []

      errors.concat(service_lifecycle(services, :start, :start))
      [servers, processes].each { |t| errors.concat(process(t, :start, :open?, :start, &)) }

      errors
    end

    # Stops all configured runners and yields results for each process/server.
    #
    # Processes and servers are stopped first and checked for shutdown, then services are stopped (proxy-only).
    #
    # @yieldparam name [String, nil] runner name
    # @yieldparam id [Object] runner-specific identifier returned by `stop` (e.g. pid or object_id)
    # @yieldparam result [Boolean] result of the port shutdown check (`true` if closed in time)
    # @return [Array<String>] lifecycle and shutdown-check errors collected while stopping
    def stop(&)
      errors = []

      [processes, servers].each { |t| errors.concat(process(t, :stop, :closed?, :stop, &)) }
      errors.concat(service_lifecycle(services, :stop, :stop))

      errors
    end

    # Stops only runners that have already been instantiated in this pool.
    #
    # This is used to rollback partial startup after a failed {#start} without constructing new runner
    # wrappers as a side effect.
    #
    # @yieldparam name [String, nil] runner name
    # @yieldparam id [Object] runner-specific identifier returned by `stop`
    # @yieldparam result [Boolean] result of the port shutdown check (`true` if closed in time)
    # @return [Array<String>] lifecycle and shutdown-check errors collected while rolling back
    def rollback(&)
      errors = []

      [existing_processes, existing_servers].each { |t| errors.concat(process(t, :stop, :closed?, :stop, &)) }
      errors.concat(service_lifecycle(existing_services, :stop, :stop))

      errors
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
      return @processes unless @processes.nil?

      @processes = []
      configuration.processes.each do |p|
        @processes << [Nonnative::Process.new(p), Nonnative::Port.new(p)]
      end

      @processes
    end

    def servers
      return @servers unless @servers.nil?

      @servers = []
      configuration.servers.each do |s|
        @servers << [s.klass.new(s), Nonnative::Port.new(s)]
      end

      @servers
    end

    def services
      return @services unless @services.nil?

      @services = []
      configuration.services.each do |s|
        @services << Nonnative::Service.new(s)
      end

      @services
    end

    def existing_processes
      @processes || []
    end

    def existing_servers
      @servers || []
    end

    def existing_services
      @services || []
    end

    def service_lifecycle(all, type_method, action)
      all.each_with_object([]) do |service, errors|
        service.send(type_method)
      rescue StandardError => e
        errors << lifecycle_error(action, service, e)
      end
    end

    def process(all, type_method, port_method, action, &)
      checks = []
      errors = []

      all.each do |type, port|
        values = type.send(type_method)
        checks << [type, values, Thread.new { check_port(port, port_method) }]
      rescue StandardError => e
        errors << lifecycle_error(action, type, e)
      end

      errors.concat(yield_results(checks, action, &))
    end

    def check_port(port, port_method)
      { result: port.send(port_method) }
    rescue StandardError => e
      { error: e }
    end

    def yield_results(checks, action, &)
      checks.each_with_object([]) do |(type, values, thread), errors|
        result = thread.value
        if result[:error]
          errors << port_error(action, type, result[:error])
        elsif block_given?
          yield type.name, values, result[:result]
        end
      end
    end

    def lifecycle_error(action, type, error)
      "#{action.to_s.capitalize} failed for #{runner_name(type)}: #{error.class} - #{error.message}"
    end

    def port_error(action, type, error)
      check = action == :start ? 'readiness' : 'shutdown'
      "#{check.capitalize} check failed for #{runner_name(type)}: #{error.class} - #{error.message}"
    end

    def runner_name(type)
      name = type.name
      return "runner '#{name}'" if name

      type.class.to_s
    end
  end
end
