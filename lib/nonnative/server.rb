# frozen_string_literal: true

module Nonnative
  class Server < Thread
    def initialize(port, timeout)
      @port = port
      @timeout = timeout
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
    attr_reader :timeout
  end
end
