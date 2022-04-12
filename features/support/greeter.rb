# frozen_string_literal: true

require_relative '../../test/grpc/nonnative/v1/greeter_services_pb'

module Nonnative
  module Features
    class Greeter < GreeterService::Service
      def say_hello(request, _call)
        Nonnative::Features::SayHelloResponse.new(message: request.name.to_s)
      end
    end
  end
end
