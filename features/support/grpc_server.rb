# frozen_string_literal: true

require_relative '../../test/grpc/helloworld_services_pb'

module Nonnative
  module Features
    class GRPCServer < Nonnative::GRPCServer
      def svc
        GreeterService.new
      end
    end
  end
end
