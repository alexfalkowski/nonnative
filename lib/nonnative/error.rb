# frozen_string_literal: true

module Nonnative
  # Parent error for all Nonnative errors.
  #
  # Rescue this type to handle Nonnative-specific errors. Public APIs may also raise standard Ruby,
  # dependency, filesystem, or transport exceptions that are not subclasses of this class.
  #
  # @see Nonnative::StartError
  # @see Nonnative::StopError
  # @see Nonnative::NotFoundError
  class Error < StandardError
  end
end
