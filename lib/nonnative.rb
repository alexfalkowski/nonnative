# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'thwait'
require 'yaml'

require 'grpc'
require 'sinatra'
require 'rest-client'
require 'puma'
require 'puma/server'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/start_error'
require 'nonnative/stop_error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/configuration'
require 'nonnative/configuration_process'
require 'nonnative/configuration_server'
require 'nonnative/configuration_proxy'
require 'nonnative/service'
require 'nonnative/command'
require 'nonnative/pool'
require 'nonnative/server'
require 'nonnative/http_client'
require 'nonnative/http_server'
require 'nonnative/grpc_server'
require 'nonnative/grpc_server'
require 'nonnative/observability'
require 'nonnative/proxy_factory'
require 'nonnative/proxy'
require 'nonnative/no_proxy'
require 'nonnative/chaos_proxy'

Thread.abort_on_exception = true

module Nonnative
  class << self
    def load_configuration(path)
      @configuration ||= Nonnative::Configuration.load_file(path) # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration

      require "nonnative/#{configuration.strategy}"
    end

    def start
      @pool ||= Nonnative::Pool.new(configuration)
      errors = []

      @pool.start do |name, id, result|
        errors << "Started #{name} with id #{id}, though did respond in time" unless result
      end

      raise Nonnative::StartError, errors.join("\n") unless errors.empty?
    end

    def stop
      return if @pool.nil?

      errors = []

      @pool.stop do |name, id, result|
        errors << "Stopped #{name} with id #{id}, though did respond in time" unless result
      end

      raise Nonnative::StopError, errors.join("\n") unless errors.empty?
    end

    def clear
      @configuration = nil
      @pool = nil
    end
  end
end
