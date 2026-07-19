# frozen_string_literal: true

module Nonnative
  # Small helper to run a block with a timeout and convert timeout errors into `false`.
  #
  # This is used internally for readiness/shutdown loops (for example port checks) where the common
  # control-flow is “keep retrying until the timeout elapses”.
  #
  # @example
  #   timeout = Nonnative::Timeout.new(1) # seconds
  #   ok = timeout.perform do
  #     # do work that may take time
  #     true
  #   end
  #   # ok is either the block result or false if the timeout elapsed
  #
  class Timeout
    # @param time [Numeric, nil] timeout duration in seconds; zero and `nil` values time out immediately
    def initialize(time)
      @time = time
    end

    # Executes the given block with the configured timeout.
    #
    # If the timeout elapses, returns `false` instead of raising `Timeout::Error`.
    # Zero and `nil` durations also return `false` without running the block.
    #
    # @yield the work to execute under a timeout
    # @return [Object, false] the block's return value, or `false` if the timeout elapsed
    def perform(&)
      return false if time.nil? || time.zero?

      ::Timeout.timeout(time, &)
    rescue ::Timeout::Error
      false
    end

    private

    attr_reader :time
  end
end
