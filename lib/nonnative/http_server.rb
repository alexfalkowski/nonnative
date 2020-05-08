# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(port)
      Application.set :port, port
      configure Application

      super port
    end

    def configure(http); end

    def perform_start
      Application.start!
    end

    def perform_stop
      Application.stop!
    end

    class Application < Sinatra::Application
      set :bind, '0.0.0.0'
    end
  end
end
