# frozen_string_literal: true

module Nonnative
  class ConfigurationProxy
    attr_accessor :type, :port, :options

    def initialize
      self.type = 'none'
      self.port = 0
      self.options = {}
    end
  end
end
