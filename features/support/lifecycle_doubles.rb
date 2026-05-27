# frozen_string_literal: true

module Nonnative
  module Features
    class StubPool
      def initialize(**options)
        @start_error = options.fetch(:start_error, nil)
        @stop_error = options.fetch(:stop_error, nil)
        @rollback_error = options.fetch(:rollback_error, nil)
        @start_errors = options.fetch(:start_errors, [])
        @stop_yields = options.fetch(:stop_yields, [])
        @rollback_yields = options.fetch(:rollback_yields, [])
      end

      def start
        raise @start_error if @start_error

        @start_errors
      end

      def stop
        raise @stop_error if @stop_error

        @stop_yields.each { |values| yield(*values) } if block_given?

        []
      end

      def rollback
        raise @rollback_error if @rollback_error

        @rollback_yields.each { |values| yield(*values) } if block_given?

        []
      end
    end

    class SeededPool < Nonnative::Pool
      def initialize(configuration, services: [], servers: [], processes: [])
        super(configuration)

        @services = services
        @servers = servers
        @processes = processes
      end
    end

    class CustomProxy < Nonnative::NoProxy
    end

    class FailingService
      attr_reader :name

      def initialize(name: nil, start_error: nil, stop_error: nil)
        @name = name
        @start_error = start_error
        @stop_error = stop_error
      end

      def start
        raise StandardError, @start_error if @start_error
      end

      def stop
        raise StandardError, @stop_error if @stop_error
      end
    end

    class RecordingService
      attr_reader :name

      def initialize(name:, events:)
        @name = name
        @events = events
      end

      def start
        events << "#{name} start"
      end

      def stop
        events << "#{name} stop"
      end

      private

      attr_reader :events
    end

    class FailingRunner
      attr_reader :name

      def initialize(name: nil, start_values: [123, true], stop_values: 123, start_error: nil, stop_error: nil)
        @name = name
        @start_values = start_values
        @stop_values = stop_values
        @start_error = start_error
        @stop_error = stop_error
      end

      def start
        raise StandardError, @start_error if @start_error

        @start_values
      end

      def stop
        raise StandardError, @stop_error if @stop_error

        @stop_values
      end
    end

    class RecordingRunner < FailingRunner
      def initialize(name:, events:, start_values: [123, true], stop_values: 123)
        super(name:, start_values:, stop_values:)

        @events = events
      end

      def start
        events << "#{name} start"

        super
      end

      def stop
        events << "#{name} stop"

        super
      end

      private

      attr_reader :events
    end

    class FailingPort
      def initialize(open_error: nil, closed_error: nil)
        @open_error = open_error
        @closed_error = closed_error
      end

      def open?
        raise StandardError, @open_error if @open_error

        true
      end

      def closed?
        raise StandardError, @closed_error if @closed_error

        true
      end
    end

    class PassingPort
      def open?
        true
      end

      def closed?
        true
      end
    end
  end
end
