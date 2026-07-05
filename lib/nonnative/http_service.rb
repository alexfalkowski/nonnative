# frozen_string_literal: true

module Nonnative
  # HTTP service run by {Nonnative::HTTPServer}.
  #
  # Subclass this instead of `Sinatra::Application` when defining an in-process HTTP server for
  # Nonnative. {Nonnative::HTTPServer} accepts a service instance and runs it under Puma.
  class HTTPService < Sinatra::Application
  end
end
