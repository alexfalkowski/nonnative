# frozen_string_literal: true

module Nonnative
  # Readiness check configuration for a managed process.
  #
  # Readiness is optional. When present, each check declares a `kind` and explicit endpoint details
  # to poll after TCP readiness succeeds.
  class ConfigurationReadiness
    KINDS = %w[http grpc].freeze

    # @return [String] readiness check kind
    attr_accessor :kind

    # @return [Integer] process readiness port
    attr_accessor :port

    # @return [String] path-only HTTP readiness path
    attr_accessor :path

    # @return [String] gRPC health service name
    attr_accessor :service

    # @param value [Hash, #to_h] readiness check attributes
    def initialize(value)
      attributes = value.respond_to?(:to_h) ? value.to_h : value
      self.kind = attribute(attributes, :kind)&.to_s
      self.port = attribute(attributes, :port)
      self.path = attribute(attributes, :path)
      self.service = attribute(attributes, :service)

      validate!
    end

    def http?
      kind == 'http'
    end

    def grpc?
      kind == 'grpc'
    end

    private

    def attribute(attributes, name)
      attributes[name] || attributes[name.to_s]
    end

    def validate!
      raise ArgumentError, "Process readiness requires 'kind'" if kind.nil?
      raise ArgumentError, "Process readiness kind must be one of: #{KINDS.join(', ')}" unless KINDS.include?(kind)
      raise ArgumentError, "Process readiness requires 'port'" if port.nil?

      validate_http! if http?
      validate_grpc! if grpc?
    end

    def validate_http!
      raise ArgumentError, "Process readiness requires 'path'" if path.nil?
      raise ArgumentError, 'Process readiness path must be path-only' unless path_only?
    end

    def validate_grpc!
      raise ArgumentError, "Process readiness requires 'service'" if service.nil?
    end

    def path_only?
      uri = URI.parse(path.to_s)

      uri.scheme.nil? && uri.host.nil?
    rescue URI::InvalidURIError
      false
    end
  end
end
