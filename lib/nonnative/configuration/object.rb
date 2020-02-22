# frozen_string_literal: true

module Nonnative
  module Configuration
    class Object
      class << self
        def load_file(path)
          file = YAML.load_file(path)

          new.tap do |c|
            c.strategy = file['strategy']

            processes(file, c)
          end
        end

        private

        def processes(file, config)
          file['processes'].each do |fd|
            config.process do |d|
              d.command = fd['command']
              d.timeout = fd['timeout']
              d.port = fd['port']
              d.file = fd['file']
            end
          end
        end
      end

      def initialize
        self.strategy = :before
        self.processes = []
      end

      attr_accessor :strategy
      attr_accessor :processes

      def process
        process = Nonnative::Configuration::Process.new
        yield process

        processes << process
      end
    end
  end
end
