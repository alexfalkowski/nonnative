# frozen_string_literal: true

module Nonnative
  # Probes a TCP readiness endpoint.
  class TCPProbe
    Target = Struct.new(:host, :timeout, keyword_init: true)

    # @param readiness [#host, #port] TCP readiness attributes
    # @param timeout [Numeric] maximum time to wait for the TCP endpoint
    def initialize(readiness, timeout:)
      @port = Nonnative::Port.new(Target.new(host: readiness.host, timeout:), readiness.port)
    end

    # Returns whether the TCP endpoint becomes connectable before the timeout elapses.
    #
    # @return [Boolean]
    def ready?
      port.open?
    end

    # Returns the checked endpoint for lifecycle diagnostics.
    #
    # @return [String]
    def endpoint
      port.endpoint
    end

    private

    attr_reader :port
  end
end
