# frozen_string_literal: true

module Nonnative
  class ProcessPool
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
      @processes ||= configuration.definitions.map { |d| [Nonnative::Process.new(d), Nonnative::Port.new(d)] }
    end

    def yield_results(prs, pos)
      prs.zip(pos).each do |pid, result|
        yield pid, result
      end
    end
  end
end
