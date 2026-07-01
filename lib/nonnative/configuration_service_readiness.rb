# frozen_string_literal: true

module Nonnative
  # Service readiness check configuration.
  #
  # Service readiness is for externally managed dependencies. The TCP target should be the dependency
  # endpoint that must be reachable before managed servers and processes start.
  class ConfigurationServiceReadiness
    KINDS = %w[tcp].freeze

    # @return [String] readiness check kind
    attr_reader :kind

    # @return [String] readiness target host
    attr_reader :host

    # @return [Integer] readiness target port
    attr_reader :port

    # @param value [Hash, #to_h] readiness check attributes
    # @return [void]
    def initialize(value)
      attributes = value.to_h.transform_keys(&:to_sym)

      @kind = attributes[:kind]&.to_s
      @host = attributes[:host]
      @port = attributes[:port]

      validate!
    end

    # Returns whether this is a TCP readiness check.
    #
    # @return [Boolean]
    def tcp?
      kind == 'tcp'
    end

    private

    def validate!
      raise ArgumentError, "Service readiness requires 'kind'" if kind.nil?
      raise ArgumentError, "Service readiness kind must be one of: #{KINDS.join(', ')}" unless KINDS.include?(kind)
      raise ArgumentError, "Service readiness requires 'host'" if host.nil?
      raise ArgumentError, "Service readiness requires 'port'" if port.nil?
    end
  end
end
