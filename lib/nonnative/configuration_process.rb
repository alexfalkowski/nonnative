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

    # @return [Array<Nonnative::ConfigurationReadiness>] optional readiness checks
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
      self.readiness = []
    end

    # Sets optional process readiness checks.
    #
    # @param value [Array<Hash, #to_h>, nil] readiness checks with required `kind` and `port`
    # @return [void]
    def readiness=(value)
      @readiness = value.nil? ? [] : build_readiness(value)
    end

    private

    def build_readiness(value)
      raise ArgumentError, 'Process readiness must be a list of checks' unless value.is_a?(Array)

      value.map { |check| Nonnative::ConfigurationReadiness.new(check) }
    end
  end
end
