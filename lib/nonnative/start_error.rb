# frozen_string_literal: true

module Nonnative
  # Raised when {Nonnative.start} fails to start one or more configured runners.
  #
  # The error message typically contains one line per failing runner.
  #
  # @see Nonnative.start
  class StartError < Nonnative::Error
  end
end
