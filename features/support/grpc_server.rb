# frozen_string_literal: true

require_relative '../../test/grpc/nonnative/v1/greeter_services_pb'

module Nonnative
  module Features
    class GRPCServer < Nonnative::GRPCServer
      def initialize(service)
        super(Greeter.new, service)
      end
    end

    class ComposedGRPCServer < Nonnative::GRPCServer
      def initialize(service)
        super([Greeter.new, HealthService.new], service)
      end
    end

    class EmptyGRPCServer < Nonnative::GRPCServer
      def initialize(service)
        super([], service)
      end
    end

    class HealthService < Grpc::Health::V1::Health::Service
      def check(_request, _call)
        Grpc::Health::V1::HealthCheckResponse.new(status: :SERVING)
      end
    end
  end
end
