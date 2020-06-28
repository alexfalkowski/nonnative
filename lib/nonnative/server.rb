# frozen_string_literal: true

module Nonnative
  class Server < Nonnative::Service
    def initialize(service)
      @id = SecureRandom.hex(5)

      super service
    end

    def start
      unless thread
        proxy.start
        @thread = Thread.new { perform_start }

        wait_start
      end

      id
    end

    def stop
      if thread
        perform_stop
        thread.terminate
        proxy.stop

        @thread = nil
        wait_stop
      end

      id
    end

    protected

    attr_reader :id, :thread
  end
end
