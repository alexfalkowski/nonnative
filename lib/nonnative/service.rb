# frozen_string_literal: true

module Nonnative
  class Service
    def initialize(service)
      @service = service
    end

    def name
      service.name
    end

    protected

    attr_reader :service

    def wait_start
      sleep 0.1
    end

    def wait_stop
      sleep 0.1
    end
  end
end
