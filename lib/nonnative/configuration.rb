# frozen_string_literal: true

module Nonnative
  class Configuration
    class << self
      def load_file(path)
        file = YAML.load_file(path)

        new.tap do |c|
          c.strategy = file['strategy']

          processes(file, c)
          servers(file, c)
          services(file, c)
        end
      end

      private

      def processes(file, config)
        processes = file['processes'] || []
        processes.each do |fd|
          config.process do |d|
            d.name = fd['name']
            d.command = command(fd)
            d.timeout = fd['timeout']
            d.port = fd['port']
            d.log = fd['log']
            d.signal = fd['signal']

            proxy d, fd['proxy']
          end
        end
      end

      def command(process)
        go = process['go']
        if go
          Nonnative.go_executable(go['output'], go['executable'], go['command'], *go['parameters'])
        else
          process['command']
        end
      end

      def servers(file, config)
        servers = file['servers'] || []
        servers.each do |fd|
          config.server do |s|
            s.name = fd['name']
            s.klass = Object.const_get(fd['class'])
            s.timeout = fd['timeout']
            s.port = fd['port']
            s.log = fd['log']

            proxy s, fd['proxy']
          end
        end
      end

      def services(file, config)
        services = file['services'] || []
        services.each do |fd|
          config.service do |s|
            s.name = fd['name']
            s.timeout = fd['timeout']
            s.port = fd['port']
            s.log = fd['log']

            proxy s, fd['proxy']
          end
        end
      end

      def proxy(server, proxy)
        return unless proxy

        server.proxy = {
          type: proxy['type'],
          port: proxy['port'],
          log: proxy['log'],
          options: proxy['options']
        }
      end
    end

    def initialize
      @strategy = Strategy.new
      @processes = []
      @servers = []
      @services = []
    end

    attr_accessor :processes, :servers, :services
    attr_reader :strategy

    def strategy=(value)
      @strategy = Strategy.new(value)
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
  end
end
