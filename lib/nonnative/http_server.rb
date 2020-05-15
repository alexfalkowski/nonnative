# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(service)
      Application.set :port, service.port
      configure Application

      super service
    end

    def configure(http)
      # Classes will add configuration
    end

    def perform_start
      Application.start!
    end

    def perform_stop
      Application.stop!
    end

    class Application < Sinatra::Application
      set :bind, '0.0.0.0'
      set :server, :puma
      set :logging, false
      set :quiet, true
    end
  end
end
