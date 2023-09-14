# frozen_string_literal: true

require 'socket'
require 'timeout'
require 'yaml'
require 'open3'
require 'securerandom'

require 'grpc'
require 'sinatra'
require 'rest-client'
require 'puma'
require 'puma/server'
require 'concurrent'
require 'cucumber'
require 'get_process_mem'
require 'rspec-benchmark'
require 'opentelemetry/sdk'

require 'nonnative/version'
require 'nonnative/error'
require 'nonnative/start_error'
require 'nonnative/stop_error'
require 'nonnative/not_found_error'
require 'nonnative/timeout'
require 'nonnative/port'
require 'nonnative/configuration'
require 'nonnative/configuration_runner'
require 'nonnative/configuration_process'
require 'nonnative/configuration_server'
require 'nonnative/configuration_service'
require 'nonnative/configuration_proxy'
require 'nonnative/runner'
require 'nonnative/process'
require 'nonnative/server'
require 'nonnative/service'
require 'nonnative/pool'
require 'nonnative/http_client'
require 'nonnative/http_server'
require 'nonnative/grpc_server'
require 'nonnative/observability'
require 'nonnative/trace'
require 'nonnative/proxy_factory'
require 'nonnative/proxy'
require 'nonnative/no_proxy'
require 'nonnative/fault_injection_proxy'
require 'nonnative/socket_pair'
require 'nonnative/close_all_socket_pair'
require 'nonnative/delay_socket_pair'
require 'nonnative/invalid_data_socket_pair'
require 'nonnative/socket_pair_factory'
require 'nonnative/go_command'
require 'nonnative/cucumber'

module Nonnative
  class << self
    attr_reader :pool

    def traces
      @traces ||= Concurrent::Array.new
    end

    def log_lines(path, predicate)
      File.readlines(path).select { |l| predicate.call(l) }
    end

    def go_executable(output, exec, cmd, *params)
      Nonnative::GoCommand.new(exec, output).executable(cmd, params)
    end

    def configuration
      @configuration ||= Nonnative::Configuration.new
    end

    def configure
      yield configuration
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
      @traces = nil
    end
  end
end
