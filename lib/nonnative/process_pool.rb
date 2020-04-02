# frozen_string_literal: true

module Nonnative
  class ProcessPool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&block)
      process_all(:start, :open?, &block)
    end

    def stop(&block)
      process_all(:stop, :closed?, &block)
    end

    private

    attr_reader :configuration

    def processes
      @processes ||= configuration.processes.map do |d|
        [Nonnative::System.new(d), Nonnative::Port.new(d)]
      end
    end

    def process_all(pr_method, po_method, &block)
      prs = []
      ths = []

      processes.each do |pr, po|
        prs << pr.send(pr_method)
        ths << Thread.new { po.send(po_method) }
      end

      ThreadsWait.all_waits(*ths)

      pos = ths.map(&:value)

      yield_results(prs, pos, &block)
    end

    def yield_results(prs, pos)
      prs.zip(pos).each do |pid, result|
        yield pid, result
      end
    end
  end
end
