# frozen_string_literal: true

module Nonnative
  class Configuration
    def initialize
      self.strategy = :before
    end

    attr_accessor :process
    attr_accessor :timeout
    attr_accessor :port
    attr_accessor :file
    attr_accessor :strategy
  end
end
