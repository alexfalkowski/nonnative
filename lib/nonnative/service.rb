# frozen_string_literal: true

module Nonnative
  class Service
    def initialize(service)
      @service = service
      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    def name
      service.name
    end

    protected

    attr_reader :service, :timeout

    def wait_start
      sleep 0.2
    end

    def wait_stop
      sleep 0.2
    end
  end
end
