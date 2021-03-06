# frozen_string_literal: true

module Nonnative
  class Timeout
    def initialize(time)
      @time = time
    end

    def perform(&block)
      ::Timeout.timeout(time, &block)
    rescue ::Timeout::Error
      false
    end

    private

    attr_reader :time
  end
end
