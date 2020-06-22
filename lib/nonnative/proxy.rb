# frozen_string_literal: true

module Nonnative
  class Proxy
    def initialize(service)
      @service = service
      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    protected

    attr_reader :service, :timeout
  end
end
