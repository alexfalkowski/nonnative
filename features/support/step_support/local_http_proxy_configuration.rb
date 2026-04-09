# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module LocalHTTPProxyConfiguration
        LOCAL_HTTP_PROXY_DEFINITIONS = [
          {
            name: 'http_proxy_target',
            klass: 'Nonnative::Features::HTTPServer',
            timeout: 1,
            host: '127.0.0.1',
            port: 4571,
            log: 'test/reports/http_proxy_target.log'
          },
          {
            name: 'local_http_proxy_server',
            klass: 'Nonnative::Features::LocalHTTPProxyServer',
            timeout: 1,
            host: '127.0.0.1',
            port: 4570,
            log: 'test/reports/local_http_proxy_server.log'
          }
        ].freeze

        def configure_local_http_proxy_server
          configure_with_defaults(url: 'http://localhost:4570') do |config|
            LOCAL_HTTP_PROXY_DEFINITIONS.each { |definition| add_local_http_proxy_server(config, definition) }
          end
        end

        private

        def add_local_http_proxy_server(config, definition)
          config.server do |server|
            server.name = definition[:name]
            server.klass = Object.const_get(definition[:klass])
            server.timeout = definition[:timeout]
            server.host = definition[:host]
            server.port = definition[:port]
            server.log = definition[:log]
          end
        end
      end
    end
  end
end
