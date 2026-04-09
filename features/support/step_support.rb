# frozen_string_literal: true

require_relative 'step_support/scenario_context'
require_relative 'step_support/process_configuration'
require_relative 'step_support/server_configuration'
require_relative 'step_support/local_http_proxy_configuration'
require_relative 'step_support/service_configuration'
require_relative 'step_support/benchmark_configuration'
require_relative 'step_support/endpoint_clients'

module Nonnative
  module Features
    module StepSupport
      DEFAULT_LOG = 'test/reports/nonnative.log'
      DEFAULT_NAME = 'test'
      DEFAULT_URL = 'http://localhost:4567'
      DEFAULT_VERSION = '1.0'

      include ScenarioContext
      include ProcessConfiguration
      include ServerConfiguration
      include LocalHTTPProxyConfiguration
      include ServiceConfiguration
      include BenchmarkConfiguration
      include EndpointClients
    end
  end
end

World(Nonnative::Features::StepSupport)
