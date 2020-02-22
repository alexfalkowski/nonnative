# frozen_string_literal: true

module Nonnative
  module Configuration
    class Process
      attr_accessor :command
      attr_accessor :timeout
      attr_accessor :port
      attr_accessor :file
    end
  end
end
