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
        end
      end

      private

      def processes(file, config)
        processes = file['processes'] || []
        processes.each do |fd|
          config.process do |d|
            d.name = fd['name']
            d.command = fd['command']
            d.timeout = fd['timeout']
            d.port = fd['port']
            d.log = fd['log']
            d.signal = fd['signal']
          end
        end
      end

      def servers(file, config)
        servers = file['servers'] || []
        servers.each do |fd|
          config.server do |s|
            s.name = fd['name']
            s.klass = Object.const_get(fd['klass'])
            s.timeout = fd['timeout']
            s.port = fd['port']
            s.log = fd['log']

            proxy = fd['proxy']

            if proxy
              s.proxy = {
                type: proxy['type'],
                port: proxy['port'],
                log: proxy['log'],
                options: proxy['options']
              }
            end
          end
        end
      end
    end

    def initialize
      @strategy = Strategy.new
      @processes = []
      @servers = []
    end

    attr_accessor :processes, :servers
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
  end
end
