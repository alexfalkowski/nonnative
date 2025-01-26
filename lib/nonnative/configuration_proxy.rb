# frozen_string_literal: true

module Nonnative
  class ConfigurationProxy
    attr_accessor :kind, :host, :port, :log, :wait, :options

    def initialize
      self.kind = 'none'
      self.host = '0.0.0.0'
      self.port = 0
      self.wait = 0.1
      self.options = {}
    end
  end
end
