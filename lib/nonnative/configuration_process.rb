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
    # @return [Proc] a callable that returns the command string to execute (e.g. `-> { "./bin/api" }`)
    # @return [String, nil] signal name to use for stopping (defaults to `"INT"` when not set)
    # @return [Numeric] readiness timeout (seconds) used when waiting for the port to open/close
    # @return [String] log file path to append process stdout/stderr to
    # @return [Hash, nil] environment variables to pass to the spawned process
    attr_accessor :command, :signal, :timeout, :log, :environment
  end
end
