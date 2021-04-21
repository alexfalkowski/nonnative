# frozen_string_literal: true

module Nonnative
  class GoCommand
    def initialize(exec, output)
      @exec = exec
      @output = output
    end

    def executable(cmd, *params)
      params = params.join(' ')
      "#{exec} #{flags(cmd, params).join(' ')} #{cmd} #{params}".strip
    end

    def execute(cmd, *params)
      Open3.popen3(executable(cmd, params)) do |_stdin, stdout, stderr, wait_thr|
        return stdout.read, stderr.read, wait_thr.value
      end
    end

    private

    attr_reader :exec, :output

    def flags(cmd, params)
      m = File.basename(exec, File.extname(exec))
      p = params.gsub(/\W/, '')
      name = [m, cmd, p].reject(&:empty?).join('-')
      path = "#{output}/#{name}"

      [
        "-test.cpuprofile=#{path}-cpu.prof",
        "-test.memprofile=#{path}-mem.prof",
        "-test.blockprofile=#{path}-block.prof",
        "-test.mutexprofile=#{path}-mutex.prof",
        "-test.coverprofile=#{path}.cov",
        "-test.trace=#{path}-trace.out"
      ]
    end
  end
end
