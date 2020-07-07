# frozen_string_literal: true

module Nonnative
  class ConfigurationServer
    attr_accessor :name
    attr_accessor :klass
    attr_accessor :timeout
    attr_accessor :port
    attr_reader :proxy

    def initialize
      @proxy = Nonnative::ConfigurationProxy.new
    end

    def proxy=(value)
      proxy.type = value[:type]
      proxy.port = value[:port]
    end
  end
end
