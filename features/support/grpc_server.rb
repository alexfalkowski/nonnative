# frozen_string_literal: true

require_relative '../../test/grpc/nonnative/v1/greeter_services_pb'

module Nonnative
  module Features
    class GRPCServer < Nonnative::GRPCServer
      def svc
        Greeter.new
      end
    end
  end
end
