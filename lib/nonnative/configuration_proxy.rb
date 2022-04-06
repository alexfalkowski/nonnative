# frozen_string_literal: true

module Nonnative
  class ConfigurationProxy
    attr_accessor :type, :host, :port, :log, :options

    def initialize
      self.type = 'none'
      self.host = '0.0.0.0'
      self.port = 0
      self.options = {}
    end
  end
end
