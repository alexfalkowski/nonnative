# frozen_string_literal: true

module Nonnative
  class ConfigurationRunner
    attr_accessor :name, :port
    attr_reader :proxy

    def initialize
      @proxy = Nonnative::ConfigurationProxy.new
    end

    def proxy=(value)
      proxy.type = value[:type]
      proxy.host = value[:host] if value[:host]
      proxy.port = value[:port]
      proxy.log = value[:log]
      proxy.options = value[:options]
    end
  end
end
