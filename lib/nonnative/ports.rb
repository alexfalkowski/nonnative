# frozen_string_literal: true

module Nonnative
  # Performs aggregate TCP readiness/shutdown checks for all configured runner ports.
  #
  # A runner is considered ready only when every configured port is open, and stopped only when every
  # configured port is closed.
  #
  # @see Nonnative::Port
  class Ports
    # @param runner [#host, #ports, #timeout] runner configuration providing connection details
    def initialize(runner)
      @runner = runner
      @ports = runner.ports.map { |port| Nonnative::Port.new(runner, port) }
      @readiness = Nonnative::HTTPProbe.new(runner) if runner.respond_to?(:readiness) && runner.readiness
    end

    # Returns whether all configured ports become connectable before their timeouts elapse.
    #
    # @return [Boolean]
    def open?
      ports.all?(&:open?) && (readiness.nil? || readiness.ready?)
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
      details << "readiness: #{readiness.endpoint}" if readiness
      log = runner.log if runner.respond_to?(:log)
      details << "log: #{log}" if log

      details.empty? ? endpoints : "#{endpoints} (#{details.join('; ')})"
    end

    private

    attr_reader :ports, :readiness, :runner
  end
end
