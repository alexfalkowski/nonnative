# frozen_string_literal: true

module Nonnative
  class Server < Nonnative::Service
    attr_reader :proxy

    def initialize(service)
      @proxy = Nonnative::ProxyFactory.create(service)

      super service
    end

    def start
      unless thread
        proxy.start
        @thread = Thread.new { perform_start }

        wait_start
      end

      object_id
    end

    def stop
      if thread
        perform_stop
        thread.terminate
        proxy.stop

        @thread = nil
        wait_stop
      end

      object_id
    end

    private

    attr_reader :thread
  end
end
