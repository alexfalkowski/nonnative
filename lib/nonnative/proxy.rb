# frozen_string_literal: true

module Nonnative
  class Proxy
    def initialize(service)
      @service = service
    end

    protected

    attr_reader :service

    def wait
      sleep service.proxy.wait
    end
  end
end
