# frozen_string_literal: true

module Nonnative
  class ConfigurationRunner
    attr_accessor :name, :host, :port
    attr_reader :proxy

    def initialize
      self.host = '0.0.0.0'
      self.port = 0

      @proxy = Nonnative::ConfigurationProxy.new
    end

    def proxy=(value)
      proxy.kind = value[:kind]
      proxy.host = value[:host] if value[:host]
      proxy.port = value[:port]
      proxy.log = value[:log]
      proxy.options = value[:options]
    end
  end
end
