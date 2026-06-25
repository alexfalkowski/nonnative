# frozen_string_literal: true

module Nonnative
  # HTTP readiness configuration for a managed process.
  #
  # Readiness is optional. When present, both `port` and `path` are required so the startup
  # check has an explicit application endpoint to poll after TCP readiness succeeds.
  class ConfigurationReadiness
    # @return [Integer] process HTTP readiness port
    attr_accessor :port

    # @return [String] HTTP readiness path
    attr_accessor :path

    # @param value [Hash, #to_h] readiness attributes
    def initialize(value)
      attributes = value.respond_to?(:to_h) ? value.to_h : value
      self.port = attribute(attributes, :port)
      self.path = attribute(attributes, :path)

      validate!
    end

    private

    def attribute(attributes, name)
      attributes[name] || attributes[name.to_s]
    end

    def validate!
      raise ArgumentError, "Process readiness requires 'port'" if port.nil?
      raise ArgumentError, "Process readiness requires 'path'" if path.nil?
    end
  end
end
