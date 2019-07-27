# frozen_string_literal: true

require 'cucumber'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/configuration'
require 'nonnative/cucumber'

module Nonnative
  class << self
    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration if block_given?
    end

    def start
      @child_pid = spawn(configuration.process)
      sleep configuration.wait
    end

    def stop
      Process.kill('SIGHUP', @child_pid)
    end
  end
end
