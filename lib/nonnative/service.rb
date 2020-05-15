# frozen_string_literal: true

module Nonnative
  class Service
    protected

    def wait_start
      sleep 0.1
    end

    def wait_stop
      sleep 0.1
    end
  end
end
