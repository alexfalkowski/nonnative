# frozen_string_literal: true

module Nonnative
  class ConfigurationProxy
    attr_accessor :strategy, :config

    def initialize
      self.strategy = 'none'
      self.config = 'toxiproxy.json'
    end
  end
end
