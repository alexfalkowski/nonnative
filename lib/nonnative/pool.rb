# frozen_string_literal: true

module Nonnative
  class Pool
    def initialize(configuration)
      @configuration = configuration
    end

    def start(&block)
      all = processes + servers
      process_all(all, :start, :open?, &block)
    end

    def stop(&block)
      all = processes + servers
      process_all(all, :stop, :closed?, &block)
    end

    private

    attr_reader :configuration

    def processes
      @processes ||= configuration.processes.map do |d|
        [Nonnative::System.new(d), Nonnative::Port.new(d)]
      end
    end

    def servers
      @servers ||= configuration.servers.map do |d|
        [d.klass.new(d.port), Nonnative::Port.new(d)]
      end
    end

    def process_all(all, pr_method, po_method, &block)
      prs = []
      ths = []

      all.each do |pr, po|
        prs << pr.send(pr_method)
        ths << Thread.new { po.send(po_method) }
      end

      ThreadsWait.all_waits(*ths)

      pos = ths.map(&:value)

      yield_results(prs, pos, &block)
    end

    def yield_results(prs, pos)
      prs.zip(pos).each do |id, result|
        yield id, result
      end
    end
  end
end
