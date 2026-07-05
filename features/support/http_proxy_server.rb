# frozen_string_literal: true

module Nonnative
  module Features
    class HTTPProxyServer < Nonnative::HTTPProxyServer
      def initialize(service)
        super('www.afalkowski.com', service)
      end
    end

    class LocalHTTPProxy < Nonnative::HTTPProxy
      def build_url(request, settings)
        query = request.query_string
        query = nil if query.empty?

        URI::HTTP.build(
          host: settings.upstream_host,
          port: settings.upstream_port,
          path: request.path_info,
          query:
        ).to_s
      end
    end

    class LocalHTTPProxyServer < Nonnative::HTTPServer
      def initialize(service)
        http_service = Class.new(LocalHTTPProxy) do
          set :upstream_host, '127.0.0.1'
          set :upstream_port, 4571
        end

        super(http_service.new, service)
      end
    end
  end
end
