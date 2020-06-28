# frozen_string_literal: true

module Nonnative
  class ConfigurationProcess
    attr_accessor :name
    attr_accessor :command
    attr_accessor :timeout
    attr_accessor :port
    attr_accessor :file
    attr_accessor :signal
    attr_accessor :proxy
  end
end
