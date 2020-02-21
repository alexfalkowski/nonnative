# frozen_string_literal: true

module Nonnative
  class Configuration
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
