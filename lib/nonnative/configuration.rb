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
    # The file is loaded using the `config` gem via {Nonnative.configurations}. Top-level attributes are
    # copied onto this object, and runner sections are transformed into configuration runner objects.
    #
    # @param path [String] path to a configuration file (typically YAML)
    # @return [void]
    def load_file(path)
      cfg = Nonnative.configurations(path)

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
      processes.each do |fd|
        process do |d|
          d.name = fd.name
          d.command = command(fd)
          d.timeout = fd.timeout
          d.wait = fd.wait if fd.wait
          d.port = fd.port
          d.log = fd.log
          d.signal = fd.signal
          d.environment = fd.environment

          proxy d, fd.proxy
        end
      end
    end

    def command(process)
      go = process.go
      if go
        params = go.parameters || []
        tools = go.tools || []

        -> { Nonnative.go_executable(tools, go.output, go.executable, go.command, *params) }
      else
        -> { process.command }
      end
    end

    def add_servers(cfg)
      servers = cfg.servers || []
      servers.each do |fd|
        server do |s|
          s.name = fd.name
          s.klass = Object.const_get(fd.class)
          s.timeout = fd.timeout
          s.wait = fd.wait if fd.wait
          s.port = fd.port
          s.log = fd.log

          proxy s, fd.proxy
        end
      end
    end

    def add_services(cfg)
      services = cfg.services || []
      services.each do |fd|
        service do |s|
          s.name = fd.name
          s.host = fd.host if fd.host
          s.port = fd.port

          proxy s, fd.proxy
        end
      end
    end

    def proxy(runner, proxy)
      return unless proxy

      p = {
        kind: proxy.kind,
        port: proxy.port,
        log: proxy.log,
        options: proxy.options
      }

      p[:host] = proxy.host if proxy.host
      p[:wait] = proxy.wait if proxy.wait

      runner.proxy = p
    end
  end
end
