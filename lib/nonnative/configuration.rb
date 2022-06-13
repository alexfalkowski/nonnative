# frozen_string_literal: true

module Nonnative
  class Configuration
    def initialize
      @processes = []
      @servers = []
      @services = []
    end

    attr_accessor :processes, :servers, :services

    def load_file(path)
      file = YAML.load_file(path)

      add_processes(file)
      add_servers(file)
      add_services(file)
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

    def service
      service = Nonnative::ConfigurationService.new
      yield service

      services << service
    end

    def process_by_name(name)
      process = processes.find { |s| s.name == name }
      raise NotFoundError, "Could not find process with name '#{name}'" if process.nil?

      process
    end

    private

    def add_processes(file)
      processes = file['processes'] || []
      processes.each do |fd|
        process do |d|
          d.name = fd['name']
          d.command = command(fd)
          d.timeout = fd['timeout']
          d.port = fd['port']
          d.log = fd['log']
          d.signal = fd['signal']
          d.environment = fd['environment']

          proxy d, fd['proxy']
        end
      end
    end

    def command(process)
      go = process['go']
      if go
        params = go['parameters'] || []
        -> { Nonnative.go_executable(go['output'], go['executable'], go['command'], *params) }
      else
        -> { process['command'] }
      end
    end

    def add_servers(file)
      servers = file['servers'] || []
      servers.each do |fd|
        server do |s|
          s.name = fd['name']
          s.klass = Object.const_get(fd['class'])
          s.timeout = fd['timeout']
          s.port = fd['port']
          s.log = fd['log']

          proxy s, fd['proxy']
        end
      end
    end

    def add_services(file)
      services = file['services'] || []
      services.each do |fd|
        service do |s|
          s.name = fd['name']
          s.host = fd['host'] if fd['host']
          s.port = fd['port']

          proxy s, fd['proxy']
        end
      end
    end

    def proxy(runner, proxy)
      return unless proxy

      p = {
        kind: proxy['kind'],
        port: proxy['port'],
        log: proxy['log'],
        options: proxy['options']
      }

      p[:host] = proxy['host'] if proxy['host']

      runner.proxy = p
    end
  end
end
