# frozen_string_literal: true

require 'socket'
require 'timeout'

require 'cucumber'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/configuration'
require 'nonnative/cucumber'
require 'nonnative/process'
require 'nonnative/logger'

module Nonnative
  class << self
    def logger
      @logger ||= Nonnative::Logger.create
    end

    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration if block_given?
    end

    def start
      @process ||= Nonnative::Process.new(configuration)
      result, pid = @process.start
      return if result

      logger.error('Process has started though did respond in time', pid: pid)
    end

    def stop
      result, pid = @process.stop
      return if result

      logger.error('Process has stopped though did respond in time', pid: pid)
    end
  end
end
