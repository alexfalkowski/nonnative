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
    # @return [Class] a class that implements `#initialize(service)` and the hooks expected by {Nonnative::Server}
    attr_accessor :klass

    # @return [Numeric] readiness timeout (seconds) used when waiting for ports to open/close
    attr_accessor :timeout

    # @return [String] log file path used by server implementations (for example Puma/gRPC log files)
    attr_accessor :log
  end
end
