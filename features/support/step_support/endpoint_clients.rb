# frozen_string_literal: true

module Nonnative
  module Features
    module StepSupport
      module EndpointClients
        def configured_process(name)
          Nonnative.configuration.process_by_name(name)
        end

        def configured_server(name)
          Nonnative.configuration.servers.find { |server| server.name == name }
        end

        def configured_service(name)
          Nonnative.configuration.services.find { |service| service.name == name }
        end

        def tcp_client_for_process(name)
          Nonnative::Features::TCPClient.new(configured_process(name).port)
        end

        def tcp_client_for_server(name)
          Nonnative::Features::TCPClient.new(configured_server(name).port)
        end

        def http_client_for_server(name)
          server = configured_server(name)

          Nonnative::Features::HTTPClient.new("http://#{server.host || 'localhost'}:#{server.port}")
        end

        def grpc_client_for_server(name, timeout: nil)
          server = configured_server(name)
          options = { channel_args: Nonnative::Header.grpc_user_agent('test 1.0') }
          options[:timeout] = timeout if timeout

          Nonnative::Features::GreeterService::Stub.new(
            "#{server.host || 'localhost'}:#{server.port}",
            :this_channel_is_insecure,
            **options
          )
        end

        def greeter_request(message = 'Hello World!')
          Nonnative::Features::SayHelloRequest.new(name: message)
        end

        def observability_request(endpoint)
          Nonnative.observability.public_send(endpoint, { headers: { content_type: :json, accept: :json } })
        end
      end
    end
  end
end
