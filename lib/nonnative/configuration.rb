# frozen_string_literal: true

module Nonnative
  class Configuration
    class << self
      def load_file(path)
        file = YAML.load_file(path)

        new.tap do |c|
          c.strategy = file['strategy']

          definitions(file, c)
        end
      end

      private

      def definitions(file, config)
        file['definitions'].each do |fd|
          config.definition do |d|
            d.process = fd['process']
            d.timeout = fd['timeout']
            d.port = fd['port']
            d.file = fd['file']
          end
        end
      end
    end

    def initialize
      self.strategy = :before
      self.definitions = []
    end

    attr_accessor :strategy
    attr_accessor :definitions

    def definition
      definition = Nonnative::Definition.new
      yield definition

      definitions << definition
    end
  end
end
