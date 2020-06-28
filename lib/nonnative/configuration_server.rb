# frozen_string_literal: true

module Nonnative
  class ConfigurationServer
    attr_accessor :name
    attr_accessor :klass
    attr_accessor :timeout
    attr_accessor :port
    attr_accessor :proxy

    def initialize
      self.proxy = Nonnative::ConfigurationProxy.new
    end
  end
end
