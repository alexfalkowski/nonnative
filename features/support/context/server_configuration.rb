# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module ServerConfiguration
        SERVERS = [
          {
            name: 'tcp_server_1',
            klass: 'Nonnative::Features::TCPServer',
            timeout: 1,
            ports: [12_323],
            log: 'test/reports/tcp_server_1.log'
          },
          {
            name: 'tcp_server_2',
            klass: 'Nonnative::Features::TCPServer',
            timeout: 1,
            ports: [12_324],
            log: 'test/reports/tcp_server_2.log'
          },
          {
            name: 'http_server_1',
            klass: 'Nonnative::Features::HTTPServer',
            timeout: 1,
            host: '127.0.0.1',
            ports: [4567],
            log: 'test/reports/http_server_1.log'
          },
          {
            name: 'http_server_2',
            klass: 'Nonnative::Features::HTTPServer',
            timeout: 1,
            ports: [4568],
            log: 'test/reports/http_server_2.log'
          },
          {
            name: 'grpc_server_1',
            klass: 'Nonnative::Features::GRPCServer',
            timeout: 1,
            ports: [9002],
            log: 'test/reports/grpc_server_1.log'
          },
          {
            name: 'grpc_server_2',
            klass: 'Nonnative::Features::GRPCServer',
            timeout: 1,
            ports: [9003],
            log: 'test/reports/grpc_server_2.log'
          }
        ].freeze

        def configure_servers_programmatically
          Nonnative::Features::Service.health_body = ''
          Nonnative::Features::Service.health_status = 200

          configure_with_defaults do |config|
            SERVERS.each { |definition| add_server(config, definition) }
          end
        end

        private

        def add_server(config, definition)
          config.server do |server|
            server.name = definition[:name]
            server.klass = resolve_klass(definition[:klass])
            server.timeout = definition[:timeout]
            server.host = definition[:host] if definition[:host]
            server.ports = definition[:ports]
            server.log = definition[:log]
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
