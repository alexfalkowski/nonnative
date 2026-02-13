# frozen_string_literal: true

module Nonnative
  # Server-specific configuration.
  #
  # A "server" is an in-process Ruby component started in a background thread and stopped via a
  # server-specific shutdown routine. It is managed by {Nonnative::Server} at runtime.
  #
  # Instances are usually created through {Nonnative::Configuration#server}.
  #
  # @see Nonnative::Configuration
  # @see Nonnative::Server
  class ConfigurationServer < ConfigurationRunner
    # @return [Class] a class that implements `#initialize(service)`, and lifecycle hooks expected by {Nonnative::Server}
    # @return [Numeric] readiness timeout (seconds) used when waiting for the port to open/close
    # @return [String] log file path used by server implementations (for example Puma/gRPC log files)
    attr_accessor :klass, :timeout, :log
  end
end
