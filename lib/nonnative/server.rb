# frozen_string_literal: true

module Nonnative
  class Server < Nonnative::Service
    def initialize(service)
      @id = SecureRandom.hex(5)

      super service
    end

    def start
      unless thread
        @thread = Thread.new { perform_start }
        wait_start
      end

      id
    end

    def stop
      if thread
        perform_stop
        thread.terminate
        @thread = nil
        wait_stop
      end

      id
    end

    protected

    attr_reader :id, :thread

    def perform_start
      proxy.start
    end

    def perform_stop
      proxy.stop
    end
  end
end
