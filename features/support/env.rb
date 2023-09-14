# frozen_string_literal: true

require 'simplecov'
require 'coveralls'

formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.start do
  add_filter '/features/'
  coverage_dir 'reports'
end

require 'nonnative'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/sinatra'
require 'opentelemetry/proto/common/v1/common_pb'
require 'opentelemetry/proto/resource/v1/resource_pb'
require 'opentelemetry/proto/trace/v1/trace_pb'
require 'opentelemetry/proto/collector/trace/v1/trace_service_pb'

OpenTelemetry::SDK.configure do |c|
  c.service_name = 'nonnative'
  c.use 'OpenTelemetry::Instrumentation::Sinatra'
  c.add_span_processor(OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(OpenTelemetry::Exporter::OTLP::Exporter.new))
end
