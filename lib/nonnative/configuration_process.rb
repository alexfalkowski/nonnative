# frozen_string_literal: true

module Nonnative
  # Process-specific configuration.
  #
  # A "process" is an OS-level child process started via `spawn` and stopped via signals.
  # It is managed by {Nonnative::Process} at runtime.
  #
  # Instances are usually created through {Nonnative::Configuration#process}.
  #
  # @see Nonnative::Configuration
  # @see Nonnative::Process
  class ConfigurationProcess < ConfigurationRunner
    # @return [Proc] a callable that returns the command to execute
    #   as a shell string or argv array
    #   (e.g. `-> { "./bin/api" }` or `-> { ["./bin/api", "--port", "8080"] }`)
    attr_accessor :command

    # @return [String, nil] signal name to use for stopping (defaults to `"INT"` when not set)
    attr_accessor :signal

    # @return [Numeric] readiness timeout (seconds) used when waiting for ports to open/close (defaults to `1.0`)
    attr_accessor :timeout

    # @return [String] log file path to append process stdout/stderr to
    attr_accessor :log

    # @return [Hash, nil] environment variables to pass to the spawned process
    attr_accessor :environment

    # @return [Nonnative::ConfigurationReadiness, nil] optional HTTP readiness check
    attr_reader :readiness

    # Creates a process configuration with bounded lifecycle defaults.
    #
    # Defaults:
    # - `timeout`: `1.0`
    #
    # @return [void]
    def initialize
      super

      self.timeout = DEFAULT_TIMEOUT
    end

    # Sets optional HTTP readiness configuration.
    #
    # @param value [Hash, #to_h, nil] readiness attributes with required `port` and `path`
    # @return [void]
    def readiness=(value)
      @readiness = value.nil? ? nil : Nonnative::ConfigurationReadiness.new(value)
    end
  end
end
