# frozen_string_literal: true

module Nonnative
  class Application < Sinatra::Application
    set :bind, '0.0.0.0'
    set :server, :puma
    set :logging, false
    set :quiet, true
  end
end
