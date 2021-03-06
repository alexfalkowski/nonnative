# frozen_string_literal: true

module Nonnative
  class ConfigurationServer
    attr_accessor :name, :klass, :timeout, :port, :log
    attr_reader :proxy

    def initialize
      @proxy = Nonnative::ConfigurationProxy.new
    end

    def proxy=(value)
      proxy.type = value[:type]
      proxy.port = value[:port]
      proxy.log = value[:log]
      proxy.options = value[:options]
    end
  end
end
