# frozen_string_literal: true

module Nonnative
  class GoCommand
    def initialize(tools, exec, output)
      @tools = tools.nil? || tools.empty? ? %w[prof trace cover] : tools
      @exec = exec
      @output = output
    end

    def executable(cmd, *params)
      params = params.join(' ')
      "#{exec} #{flags(cmd, params).join(' ')} #{cmd} #{params}".strip
    end

    private

    attr_reader :tools, :exec, :output

    def flags(cmd, params)
      suffix = SecureRandom.alphanumeric(4)
      m = File.basename(exec, File.extname(exec))
      p = params.gsub(/\W/, '')
      name = [m, cmd, p].reject(&:empty?).join('-')
      path = "#{output}/#{name}-#{suffix}"

      prof(path) + trace(path) + cover(path)
    end

    def prof(path)
      return [] unless tools.include?('prof')

      [
        "-test.cpuprofile=#{path}-cpu.prof",
        "-test.memprofile=#{path}-mem.prof",
        "-test.blockprofile=#{path}-block.prof",
        "-test.mutexprofile=#{path}-mutex.prof"
      ]
    end

    def trace(path)
      return [] unless tools.include?('trace')

      [
        "-test.trace=#{path}-trace.out"
      ]
    end

    def cover(path)
      return [] unless tools.include?('cover')

      [
        "-test.coverprofile=#{path}.cov"
      ]
    end
  end
end
