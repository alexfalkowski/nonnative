# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(service)
      @queue = Queue.new

      super service
    end

    def configure(http)
      # Classes will add configuration
    end

    protected

    def perform_start
      Application.set :port, proxy.port
      configure Application

      Application.start! do |server|
        queue << server
      end
    end

    def perform_stop
      Application.stop!
    end

    def wait_start
      timeout.perform do
        queue.pop
      end
    end

    private

    attr_reader :queue
  end
end
