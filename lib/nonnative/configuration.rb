# frozen_string_literal: true

module Nonnative
  class Configuration
    def initialize
      @proxy = Nonnative::ConfigurationProxy.new
      @processes = []
      @servers = []
    end

    attr_accessor :proxy, :processes, :servers, :services

    def load_file(path)
      cfg = Nonnative.configurations(path)

      add_processes(cfg)
      add_servers(cfg)
    end

    def process
      process = Nonnative::ConfigurationProcess.new
      yield process

      processes << process
    end

    def server
      server = Nonnative::ConfigurationServer.new
      yield server

      servers << server
    end

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
        end
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
  end
end
