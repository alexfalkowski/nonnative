# frozen_string_literal: true

module Nonnative
  class ConfigurationRunner
    attr_accessor :name, :host, :port, :wait

    def initialize
      self.host = '0.0.0.0'
      self.port = 0
      self.wait = 0.1
    end
  end
end
