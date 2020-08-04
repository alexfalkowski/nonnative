# frozen_string_literal: true

module Nonnative
  class GoCommand
    def initialize(main, output)
      @main = main
      @output = output
    end

    def executable(cmd, *params)
      params = params.join(' ')
      "#{main} #{flags(cmd, params).join(' ')} #{cmd} #{params}"
    end

    def execute(cmd, *params)
      Open3.popen3(executable(cmd, params)) do |_stdin, stdout, stderr, wait_thr|
        return stdout.read, stderr.read, wait_thr.value
      end
    end

    private

    attr_reader :main, :output

    def flags(cmd, params)
      m = File.basename(main, File.extname(main))
      p = params.gsub(/\W/, '')
      path = "#{output}/#{m}-#{cmd}-#{p}"

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
