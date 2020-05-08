# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    class << self
      def configure
        yield Application if block_given?
      end
    end

    def initialize(port)
      self.class.configure do |app|
        app.set :port, port
      end

      super port
    end

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
