# frozen_string_literal: true

module Nonnative
  # Base class for all Nonnative errors.
  #
  # Catch this error type if you want to handle any exception raised by this gem.
  #
  # @see Nonnative::StartError
  # @see Nonnative::StopError
  # @see Nonnative::NotFoundError
  class Error < StandardError
  end
end
