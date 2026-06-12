# frozen_string_literal: true

module Nonnative
  module Features
    module Context
      module ServiceConnections
        def stop_service_runner_while_clients_connect(runner, service)
          connections = open_service_connections(service, 20)
          mutex = Mutex.new
          stop_connecting = false
          connector = connect_to_service_until_stopped(service, connections, mutex, -> { stop_connecting })

          begin
            sleep 0.05
            capture_result(:@stop_result, :@stop_error) { runner.stop }
          ensure
            stop_connecting = true
            connector&.join
            close_service_connections(connections, mutex)
          end
        end

        private

        def open_service_connections(service, count)
          Array.new(count).filter_map { open_service_connection(service) }
        end

        def connect_to_service_until_stopped(service, connections, mutex, stopped)
          Thread.new do
            50.times do
              break if stopped.call

              socket = open_service_connection(service)
              mutex.synchronize { connections << socket } if socket
              sleep 0.001
            end
          end
        end

        def open_service_connection(service)
          TCPSocket.open(service.host, service.port)
        rescue SystemCallError, IOError
          nil
        end

        def close_service_connections(connections, mutex)
          mutex.synchronize { connections.each { |socket| close_service_connection(socket) } }
        end

        def close_service_connection(socket)
          socket.close unless socket.closed?
        rescue IOError
          nil
        end
      end
    end
  end
end
