# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(app, service)
      @server = ::Rackup::Handler.get('webrick')
      @app = app

      super(service)
    end

    protected

    def perform_start
      file = File.open(service.log, 'a')
      logs = [
        [Logger.new(file), WEBrick::AccessLog::COMBINED_LOG_FORMAT]
      ]

      server.run(app, Host: proxy.host, Port: proxy.port,
                      Logger: WEBrick::Log.new(file),
                      AccessLog: logs)
    end

    def perform_stop
      server.shutdown
    end

    private

    attr_reader :queue, :server, :app
  end
end
