# frozen_string_literal: true

module Nonnative
  class Runner
    attr_reader :proxy

    def initialize(service)
      @service = service
      @proxy = Nonnative::ProxyFactory.create(service)
    end

    def name
      service.name
    end

    protected

    attr_reader :service

    def wait_start
      sleep service.wait
    end

    def wait_stop
      sleep service.wait
    end
  end
end
