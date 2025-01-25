# frozen_string_literal: true

module Nonnative
  class HTTPServer < Nonnative::Server
    def initialize(service)
      @server = ::Rackup::Handler.get('webrick')

      super
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

    attr_reader :queue, :server
  end
end
