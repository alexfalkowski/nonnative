# frozen_string_literal: true

module Nonnative
  # Performs aggregate TCP readiness/shutdown checks for all configured runner ports.
  #
  # A runner is considered ready only when every configured port is open and every configured
  # HTTP/gRPC readiness probe reports ready, and stopped only when every configured port is closed.
  #
  # @see Nonnative::Port
  class Ports
    # @param runner [#host, #ports, #timeout] runner configuration providing connection details
    def initialize(runner)
      @runner = runner
      @ports = runner.ports.map { |port| Nonnative::Port.new(runner, port) }
      @readiness = readiness_probes
    end

    # Returns whether all configured ports become connectable and all configured HTTP/gRPC readiness
    # probes report ready before their timeouts elapse.
    #
    # @return [Boolean]
    def open?
      ports.all?(&:open?) && readiness.all?(&:ready?)
    end

    # Returns whether all configured ports become non-connectable before their timeouts elapse.
    #
    # @return [Boolean]
    def closed?
      ports.all?(&:closed?)
    end

    # Returns the checked endpoints for lifecycle diagnostics.
    #
    # @return [String]
    def endpoints
      ports.map(&:endpoint).join(', ')
    end

    # Returns endpoint and log context for lifecycle errors.
    #
    # @return [String]
    def description
      details = []
      details << "readiness: #{readiness.map(&:endpoint).join(', ')}" if readiness.any?
      log = runner.log if runner.respond_to?(:log)
      details << "log: #{log}" if log

      details.empty? ? endpoints : "#{endpoints} (#{details.join('; ')})"
    end

    private

    attr_reader :ports, :readiness, :runner

    def readiness_probes
      return [] unless runner.respond_to?(:readiness)

      runner.readiness.map { |check| readiness_probe(check) }
    end

    def readiness_probe(check)
      case check.kind
      when 'http'
        Nonnative::HTTPProbe.new(runner, check)
      when 'grpc'
        Nonnative::GRPCProbe.new(runner, check)
      end
    end
  end
end
