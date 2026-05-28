# frozen_string_literal: true

require_relative 'context/scenario_context'
require_relative 'context/process_configuration'
require_relative 'context/server_configuration'
require_relative 'context/http_proxy_configuration'
require_relative 'context/service_configuration'
require_relative 'context/benchmark_configuration'
require_relative 'context/endpoint_clients'

module Nonnative
  module Features
    module Context
      DEFAULT_LOG = 'test/reports/nonnative.log'
      DEFAULT_NAME = 'test'
      DEFAULT_URL = 'http://localhost:4567'
      DEFAULT_VERSION = '1.0'

      include ScenarioContext
      include ProcessConfiguration
      include ServerConfiguration
      include HTTPProxyConfiguration
      include ServiceConfiguration
      include BenchmarkConfiguration
      include EndpointClients
    end
  end
end

World(Nonnative::Features::Context)
