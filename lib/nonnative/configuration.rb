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
            d.file = fd['file']
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
          end
        end
      end
    end

    def initialize
      self.strategy = :before
      self.processes = []
      self.servers = []
    end

    attr_accessor :strategy
    attr_accessor :processes
    attr_accessor :servers

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
