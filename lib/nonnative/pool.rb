# frozen_string_literal: true

module Nonnative
  # Orchestrates lifecycle for configured processes, servers and services.
  #
  # A pool is created when {Nonnative.start} is called and is accessible via {Nonnative.pool}.
  #
  # Lifecycle order is important:
  # - On start: services, then servers, then processes; each tier completes readiness before the next
  # - On stop: processes, then servers, then services
  #
  # Readiness uses TCP port checks plus optional process HTTP/gRPC probes and optional service TCP
  # checks. Shutdown uses configured TCP port checks.
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

    # Starts all configured runners and collects lifecycle and readiness errors.
    #
    # Externally managed services are handled first and checked for opt-in readiness. Servers are then
    # started and checked for readiness, followed by processes. Each readiness failure is described
    # with the runner and, for a process that exited early, its termination detail.
    #
    # @return [Array<String>] lifecycle and readiness-check errors collected while starting
    def start
      errors = []

      errors.concat(service_lifecycle(services, :start, :start))
      service_readiness_errors = check_service_readiness(services)
      errors.concat(service_readiness_errors)
      return errors if errors.any?

      [servers, processes].each { |runners| errors.concat(run_lifecycle_checks(runners, :start, :open?, :start)) }

      errors
    end

    # Stops all configured runners and collects lifecycle and shutdown errors.
    #
    # Processes and servers are stopped first and checked for shutdown, then service proxies are
    # stopped when configured.
    #
    # @return [Array<String>] lifecycle and shutdown-check errors collected while stopping
    def stop
      errors = []

      [processes, servers].each { |runners| errors.concat(run_lifecycle_checks(runners, :stop, :closed?, :stop)) }
      errors.concat(service_lifecycle(services, :stop, :stop))

      errors
    end

    # Stops only runners that have already been instantiated in this pool.
    #
    # This is used to rollback partial startup after a failed {#start} without constructing new runner
    # wrappers as a side effect.
    #
    # @return [Array<String>] lifecycle and shutdown-check errors collected while rolling back
    def rollback
      errors = []

      [existing_processes, existing_servers].each do |runners|
        errors.concat(run_lifecycle_checks(runners, :stop, :closed?, :rollback))
      end
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

    # Resets service proxies in this pool.
    #
    # This is used by the Cucumber `@reset` hook and is safe to call any time after the pool is created.
    #
    # @return [void]
    def reset
      services.each { |s| s.proxy.reset }
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
        @processes << [Nonnative::Process.new(p), Nonnative::Ports.new(p)]
      end

      @processes
    end

    def servers
      return @servers unless @servers.nil?

      @servers = []
      configuration.servers.each do |s|
        @servers << [s.klass.new(s), Nonnative::Ports.new(s)]
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

    def check_service_readiness(all)
      all.each_with_object([]) do |service, errors|
        next unless service.respond_to?(:readiness)

        checks = service.readiness.map { |readiness| Nonnative::TCPProbe.new(readiness, timeout: service.timeout) }
        errors << service_readiness_error(service, checks) unless checks.all?(&:ready?)
      rescue StandardError => e
        errors << port_error(:start, service, e)
      end
    end

    def run_lifecycle_checks(runners, lifecycle_method, port_method, phase)
      action = phase == :start ? :start : :stop
      checks = []
      errors = []

      runners.each do |runner, port|
        values = runner.send(lifecycle_method)
        checks << [runner, values, port, Thread.new { check_port(port, port_method) }]
      rescue StandardError => e
        errors << lifecycle_error(action, runner, e)
      end

      errors.concat(lifecycle_results(checks, phase, action))
    end

    def check_port(port, port_method)
      { result: port.send(port_method) }
    rescue StandardError => e
      { error: e }
    end

    def lifecycle_results(checks, phase, action)
      checks.each_with_object([]) do |(runner, values, port, thread), errors|
        result = thread.value
        if result[:error]
          errors << port_error(action, runner, result[:error])
        else
          errors.concat(readiness_errors(phase, runner, values, result[:result], port))
        end
      end
    end

    def readiness_errors(phase, runner, values, ready, port)
      case phase
      when :start then start_errors(runner, values, ready, port)
      when :stop then stop_errors(runner, values, ready, port)
      else rollback_errors(runner, values, ready, port)
      end
    end

    def start_errors(runner, values, ready, port)
      id, started = values
      return [] if started && ready

      message = "Started #{runner.name} with id #{id}, though did not respond in time for #{port.description}"
      detail = runner.termination
      [detail ? "#{message}; #{detail}" : message]
    end

    def stop_errors(runner, values, ready, port)
      id, stopped = Array(values).then { |v| [v.first, v.fetch(1, true)] }
      errors = []
      errors << "Stopped #{runner.name} with id #{id}, though did not respond in time for #{port.description}" unless ready
      errors << "Stopped #{runner.name} with id #{id}, though the process did not exit in time" unless stopped
      errors
    end

    def rollback_errors(runner, values, ready, port)
      id, stopped = Array(values).then { |v| [v.first, v.fetch(1, true)] }
      errors = []
      errors << "Rollback failed for #{runner.name} with id #{id}, because it did not stop in time for #{port.description}" unless ready
      errors << "Rollback failed for #{runner.name} with id #{id}, because the process did not exit in time" unless stopped
      errors
    end

    def lifecycle_error(action, type, error)
      "#{action.to_s.capitalize} failed for #{runner_name(type)}: #{error.class} - #{error.message}"
    end

    def port_error(action, type, error)
      check = action == :start ? 'readiness' : 'shutdown'
      "#{check.capitalize} check failed for #{runner_name(type)}: #{error.class} - #{error.message}"
    end

    def service_readiness_error(service, checks)
      "Started #{runner_name(service)}, though did not respond in time for readiness: #{checks.map(&:endpoint).join(', ')}"
    end

    def runner_name(type)
      name = type.name
      return "runner '#{name}'" if name

      type.class.to_s
    end
  end
end
