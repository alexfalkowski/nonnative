# frozen_string_literal: true

module Nonnative
  class ConfigurationProxy
    attr_accessor :type, :port

    def initialize
      self.type = 'none'
      self.port = 0
    end
  end
end
