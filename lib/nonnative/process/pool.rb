# frozen_string_literal: true

module Nonnative
  module Process
    class Pool
      def initialize(configuration)
        @configuration = configuration
      end

      def start(&block)
        prs = processes.map { |p, _| p.start }
        pos = processes.map { |_, p| Thread.new { p.open? } }.map(&:value)

        yield_results(prs, pos, &block)
      end

      def stop(&block)
        prs = processes.map { |p, _| p.stop }
        pos = processes.map { |_, p| Thread.new { p.closed? } }.map(&:value)

        yield_results(prs, pos, &block)
      end

      private

      attr_reader :configuration

      def processes
        @processes ||= configuration.processes.map do |d|
          [Nonnative::Process::System.new(d), Nonnative::Process::Port.new(d)]
        end
      end

      def yield_results(prs, pos)
        prs.zip(pos).each do |pid, result|
          yield pid, result
        end
      end
    end
  end
end
