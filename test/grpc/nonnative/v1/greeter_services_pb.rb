# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: nonnative/v1/greeter.proto for package 'Nonnative.Features'

require 'grpc'
require_relative 'greeter_pb'

module Nonnative
  module Features
    module GreeterService
      class Service
        include ::GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'nonnative.v1.GreeterService'

        rpc :SayHello, ::Nonnative::Features::SayHelloRequest, ::Nonnative::Features::SayHelloResponse
      end

      Stub = Service.rpc_stub_class
    end
  end
end