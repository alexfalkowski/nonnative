# frozen_string_literal: true

module Nonnative
  class Runner
    attr_reader :proxy

    def initialize(service)
      @service = service
      @timeout = Nonnative::Timeout.new(service.timeout)
      @proxy = Nonnative::ProxyFactory.create(service)
    end

    def name
      service.name
    end

    protected

    attr_reader :service, :timeout

    def wait_start
      sleep 0.1
    end

    def wait_stop
      sleep 0.1
    end
  end
end