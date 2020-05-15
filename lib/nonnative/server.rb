# frozen_string_literal: true

module Nonnative
  class Server
    def initialize(port)
      @port = port
      @id = SecureRandom.hex(5)
    end

    def name
      self.class.to_s
    end

    def start
      unless thread
        @thread = Thread.new { perform_start }
        sleep 0.1 # Servers take time to start
      end

      id
    end

    def stop
      if thread
        perform_stop
        thread.terminate
        @thread = nil
        sleep 0.1 # Servers take time to stop
      end

      id
    end

    attr_reader :port, :id, :thread
  end
end
