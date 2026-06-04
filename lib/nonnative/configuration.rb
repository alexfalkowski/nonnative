# frozen_string_literal: true

module Nonnative
  # The gem configuration object.
  #
  # You can populate configuration either programmatically via the DSL ({#process}, {#server}, {#service}),
  # or by loading a YAML file via {#load_file}.
  #
  # The configuration is consumed when {Nonnative.start} is called.
  #
  # == Programmatic configuration
  #
  #   Nonnative.configure do |config|
  #     config.name = 'example'
  #     config.url = 'http://127.0.0.1:8080'
  #     config.log = 'test.log'
  #
  #     config.process do |p|
  #       p.name = 'api'
  #       p.command = -> { './bin/api' }
  #       p.host = '127.0.0.1'
  #       p.port = 8080
  #       p.timeout = 10
  #       p.log = 'api.log'
  #     end
  #   end
  #
  # == File-based configuration
  #
  #   Nonnative.configure do |config|
  #     config.load_file('features/configs/processes.yml')
  #   end
  #
  class Configuration
    # Creates an empty configuration.
    #
    # @return [void]
    def initialize
      @processes = []
      @servers = []
      @services = []
    end

    # @return [String, nil] logical system name (used for observability endpoints)
    # @return [String, nil] configuration version
    # @return [String, nil] base URL for observability queries (for example `"http://127.0.0.1:8080"`)
    # @return [String, nil] path to the Nonnative log file
    # @return [Array<Nonnative::ConfigurationProcess>] configured processes
    # @return [Array<Nonnative::ConfigurationServer>] configured in-process servers
    # @return [Array<Nonnative::ConfigurationService>] configured services (proxy-only)
    attr_accessor :name, :version, :url, :log, :processes, :servers, :services

    # Loads a configuration file and appends its runners to this instance.
    #
    # The file is loaded using safe YAML parsing. ERB is not evaluated,
    # arbitrary object deserialization is not allowed, top-level attributes are copied onto this object,
    # and runner sections are transformed into configuration runner objects.
    #
    # @param path [String] path to a configuration file (typically YAML)
    # @return [void]
    def load_file(path)
      cfg = Nonnative::ConfigurationFile.load(path)

      self.version = cfg.version
      self.name = cfg.name
      self.url = cfg.url
      self.log = cfg.log

      add_processes(cfg)
      add_servers(cfg)
      add_services(cfg)
    end

    # Adds a process configuration entry.
    #
    # @yieldparam process [Nonnative::ConfigurationProcess]
    # @return [void]
    def process
      process = Nonnative::ConfigurationProcess.new
      yield process

      processes << process
    end

    # Adds a server configuration entry.
    #
    # @yieldparam server [Nonnative::ConfigurationServer]
    # @return [void]
    def server
      server = Nonnative::ConfigurationServer.new
      yield server

      servers << server
    end

    # Adds a service configuration entry.
    #
    # A "service" does not manage a Ruby thread or OS process; it exists so that a proxy can be started
    # and controlled for an external dependency.
    #
    # @yieldparam service [Nonnative::ConfigurationService]
    # @return [void]
    def service
      service = Nonnative::ConfigurationService.new
      yield service

      services << service
    end

    # Finds a configured process by name.
    #
    # @param name [String]
    # @return [Nonnative::ConfigurationProcess]
    # @raise [Nonnative::NotFoundError] if no matching process exists
    def process_by_name(name)
      process = processes.find { |s| s.name == name }
      raise NotFoundError, "Could not find process with name '#{name}'" if process.nil?

      process
    end

    private

    def add_processes(cfg)
      processes = cfg.processes || []
      processes.each do |loaded_process|
        process do |process_config|
          process_config.command = command(loaded_process)
          process_config.signal = loaded_process.signal
          process_config.environment = loaded_process.environment
          runner_attributes(process_config, loaded_process)

          assign_proxy(process_config, loaded_process.proxy)
        end
      end
    end

    def command(process)
      go = process.go
      if go
        params = go.parameters || []
        tools = go.tools || []

        -> { Nonnative.go_argv(tools, go.output, go.executable, go.command, *params) }
      else
        -> { process.command }
      end
    end

    def add_servers(cfg)
      servers = cfg.servers || []
      servers.each do |loaded_server|
        server do |server_config|
          server_config.klass = Object.const_get(server_class_name(loaded_server))
          runner_attributes(server_config, loaded_server)

          assign_proxy(server_config, loaded_server.proxy)
        end
      end
    end

    def add_services(cfg)
      services = cfg.services || []
      services.each do |loaded_service|
        service do |service_config|
          service_config.name = loaded_service.name
          service_config.host = loaded_service.host if loaded_service.host
          service_config.port = loaded_service.port

          assign_proxy(service_config, loaded_service.proxy)
        end
      end
    end

    def server_class_name(server)
      values = server.to_h
      values[:class] || values.fetch('class')
    end

    def runner_attributes(runner, loaded)
      runner.name = loaded.name
      runner.timeout = loaded.timeout
      runner.wait = loaded.wait if loaded.wait
      runner.host = loaded.host if loaded.host
      runner.port = loaded.port
      runner.log = loaded.log if loaded.respond_to?(:log)
    end

    def assign_proxy(runner, loaded_proxy)
      return unless loaded_proxy

      proxy_attributes = {
        kind: loaded_proxy.kind,
        port: loaded_proxy.port,
        log: loaded_proxy.log,
        options: loaded_proxy.options
      }

      proxy_attributes[:host] = loaded_proxy.host if loaded_proxy.host
      proxy_attributes[:wait] = loaded_proxy.wait if loaded_proxy.wait

      runner.proxy = proxy_attributes
    end
  end
end
