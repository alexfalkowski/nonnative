# frozen_string_literal: true

module Nonnative
  class Server < Thread
    def initialize(port)
      @port = port
      self.abort_on_exception = true

      super do
        perform_start
      end
    end

    def name
      self.class.to_s
    end

    def start
      object_id
    end

    def stop
      perform_stop
      object_id
    end

    attr_reader :port

    def perform_start; end

    def perform_stop; end
  end
end
