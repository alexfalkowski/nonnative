# frozen_string_literal: true

require_relative '../../test/grpc/helloworld_services_pb'

module Nonnative
  module Features
    class GreeterService < Greeter::Service
      def say_hello(request, _call)
        Nonnative::Features::HelloReply.new(message: request.name.to_s)
      end
    end

    class GRPCServer < Nonnative::GRPCServer
      def configure(grpc)
        grpc.handle(GreeterService.new)
      end
    end
  end
end
