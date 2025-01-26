# frozen_string_literal: true

module Nonnative
  class ConfigurationRunner
    attr_accessor :name, :host, :port, :wait
    attr_reader :proxy

    def initialize
      self.host = '0.0.0.0'
      self.port = 0
      self.wait = 0.1

      @proxy = Nonnative::ConfigurationProxy.new
    end

    def proxy=(value)
      proxy.kind = value[:kind]
      proxy.host = value[:host] if value[:host]
      proxy.port = value[:port]
      proxy.log = value[:log]
      proxy.wait = value[:wait] if value[:wait]
      proxy.options = value[:options]
    end
  end
end
