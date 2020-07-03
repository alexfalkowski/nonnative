# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    protected

    def perform_start
      options = {
        Host: '0.0.0.0',
        Port: proxy.port,
        Logger: ::WEBrick::Log.new('/dev/null'),
        AccessLog: []
      }

      Rack::Handler::WEBrick.run(app, options) do |server|
        @server = server
      end
    end

    def perform_stop
      server.shutdown
    end

    private

    attr_reader :queue, :server
  end
end
