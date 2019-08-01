# frozen_string_literal: true

require 'socket'
require 'timeout'

require 'cucumber'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/configuration'
require 'nonnative/cucumber'
require 'nonnative/process'

module Nonnative
  class << self
    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration if block_given?
    end

    def start
      @process ||= Nonnative::Process.new(configuration)
      @process.start
    end

    def stop
      @process.stop
    end
  end
end
