# frozen_string_literal: true

module Nonnative
  class Server < Nonnative::Service
    def initialize(service)
      @service = service
      @id = SecureRandom.hex(5)
    end

    def name
      self.class.to_s
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

    attr_reader :service, :id, :thread
  end
end
