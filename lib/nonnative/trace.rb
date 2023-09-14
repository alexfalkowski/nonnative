# frozen_string_literal: true

module Nonnative
  class Trace < Nonnative::HTTPServer
    def app
      Application.new
    end
  end

  class Application < Sinatra::Application
    configure do
      set :server_settings, log_requests: true
    end

    post '/v1/traces' do
      request.body.rewind

      r = Opentelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest.decode(Zlib.gunzip(request.body.read))
      s = r.to_h[:resource_spans]

      Nonnative.traces.concat s
    end
  end
end
