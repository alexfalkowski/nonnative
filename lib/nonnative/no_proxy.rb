# frozen_string_literal: true

module Nonnative
  class NoProxy < Proxy
    def start
      # Do nothing.
    end

    def stop
      # Do nothing.
    end

    def port
      service.port
    end
  end
end
