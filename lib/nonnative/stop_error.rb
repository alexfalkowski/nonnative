# frozen_string_literal: true

module Nonnative
  # Raised when {Nonnative.stop} fails to stop one or more configured runners within the configured timeouts.
  #
  # The error message typically contains one line per runner that did not stop cleanly in time.
  #
  # @see Nonnative.stop
  class StopError < Nonnative::Error
  end
end
