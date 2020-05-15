# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(service)
      @timeout = Nonnative::Timeout.new(service.timeout)
      @queue = Queue.new

      Application.set :port, service.port
      configure Application

      super service
    end

    def configure(http)
      # Classes will add configuration
    end

    def perform_start
      Application.start! do |server|
        queue << server
      end
    end

    def perform_stop
      Application.stop!
    end

    protected

    def wait_start
      timeout.perform do
        queue.pop
      end
    end

    private

    attr_reader :timeout, :queue
  end
end
