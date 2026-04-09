# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module ServerConfiguration
        SERVER_DEFINITIONS = [
          {
            name: 'tcp_server_1',
            klass: 'Nonnative::Features::TCPServer',
            timeout: 1,
            port: 12_323,
            log: 'test/reports/tcp_server_1.log'
          },
          {
            name: 'tcp_server_2',
            klass: 'Nonnative::Features::TCPServer',
            timeout: 1,
            port: 12_324,
            log: 'test/reports/tcp_server_2.log'
          },
          {
            name: 'http_server_1',
            klass: 'Nonnative::Features::HTTPServer',
            timeout: 1,
            host: '127.0.0.1',
            port: 4567,
            log: 'test/reports/http_server_1.log',
            proxy: {
              kind: 'fault_injection',
              host: '127.0.0.1',
              port: 20_001,
              log: 'test/reports/proxy_http_server_1.log',
              wait: 1,
              options: { delay: 10 }
            }
          },
          {
            name: 'http_server_2',
            klass: 'Nonnative::Features::HTTPServer',
            timeout: 1,
            port: 4568,
            log: 'test/reports/http_server_2.log',
            proxy: {
              kind: 'fault_injection',
              port: 20_002,
              log: 'test/reports/proxy_http_server_2.log',
              wait: 1,
              options: { delay: 2 }
            }
          },
          {
            name: 'grpc_server_1',
            klass: 'Nonnative::Features::GRPCServer',
            timeout: 1,
            port: 9002,
            log: 'test/reports/grpc_server_1.log',
            proxy: {
              kind: 'fault_injection',
              port: 20_003,
              log: 'test/reports/proxy_grpc_server_1.log',
              wait: 1,
              options: { delay: 5 }
            }
          },
          {
            name: 'grpc_server_2',
            klass: 'Nonnative::Features::GRPCServer',
            timeout: 1,
            port: 9003,
            log: 'test/reports/grpc_server_2.log',
            proxy: {
              kind: 'fault_injection',
              port: 20_004,
              log: 'test/reports/proxy_grpc_server_2.log',
              wait: 1,
              options: { delay: 7 }
            }
          }
        ].freeze

        def configure_servers_programmatically
          configure_with_defaults do |config|
            SERVER_DEFINITIONS.each { |definition| add_server(config, definition) }
          end
        end

        private

        def add_server(config, definition)
          config.server do |server|
            server.name = definition[:name]
            server.klass = resolve_klass(definition[:klass])
            server.timeout = definition[:timeout]
            server.host = definition[:host] if definition[:host]
            server.port = definition[:port]
            server.log = definition[:log]
            server.proxy = definition[:proxy] if definition[:proxy]
          end
        end

        def resolve_klass(klass)
          return klass if klass.is_a?(Class)

          Object.const_get(klass)
        end
      end
    end
  end
end
