# frozen_string_literal: true

require 'socket'
require 'timeout'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/configuration'
require 'nonnative/definition'
require 'nonnative/process'
require 'nonnative/process_pool'
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

      require "nonnative/#{configuration.strategy}"
    end

    def start
      @process_pool ||= Nonnative::ProcessPool.new(configuration)

      @process_pool.start do |result, pid|
        logger.error('Process has started though did respond in time', pid: pid) unless result
      end
    end

    def stop
      @process_pool.stop do |result, pid|
        logger.error('Process has stopped though did respond in time', pid: pid) unless result
      end
    end
  end
end
