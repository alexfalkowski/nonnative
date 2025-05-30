# frozen_string_literal: true

module Nonnative
  class Server < Runner
    def initialize(service)
      super

      @timeout = Nonnative::Timeout.new(service.timeout)
    end

    def start
      unless thread
        proxy.start
        @thread = Thread.new { perform_start }

        wait_start

        Nonnative.logger.info "started server '#{service.name}'"
      end

      [object_id, true]
    end

    def stop
      if thread
        perform_stop
        thread.terminate
        proxy.stop

        @thread = nil
        wait_stop

        Nonnative.logger.info "stopped server '#{service.name}'"
      end

      object_id
    end

    private

    attr_reader :thread, :timeout
  end
end
