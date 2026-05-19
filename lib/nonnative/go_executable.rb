# frozen_string_literal: true

module Nonnative
  # Builds commands for running a Go test binary with optional profiling/trace/coverage flags.
  #
  # This helper is used by YAML configuration when a process has a `go:` section
  # (see {Nonnative::Configuration}).
  #
  # The generated flags use Go's `testing` package flags (e.g. `-test.cpuprofile=...`), so this
  # is intended to run a binary compiled from `go test -c`.
  #
  # ## Tools
  #
  # Tools can be enabled/disabled via the `tools` list. Supported values:
  #
  # - `"prof"`: cpu/mem/block/mutex profiles
  # - `"trace"`: execution trace output
  # - `"cover"`: coverage profile output
  #
  # If `tools` is `nil` or empty, all tools (`prof`, `trace`, `cover`) are enabled.
  #
  # Parameter strings are parsed into argv words using shell-style quoting.
  #
  # @example
  #   executable = Nonnative::GoExecutable.new(%w[prof cover], './svc.test', 'reports')
  #   executable.argv('serve', '--config', 'config.yaml')
  #   # => ["./svc.test", "-test.cpuprofile=...", "-test.coverprofile=...", "serve", "--config", "config.yaml"]
  #
  # @see Nonnative.go_command
  # @see Nonnative.go_argv
  class GoExecutable
    # @param tools [Array<String>, nil] tool names to enable (see class docs)
    # @param exec [String] path to the compiled Go test binary
    # @param output [String] output directory for generated files
    def initialize(tools, exec, output)
      @tools = tools.nil? || tools.empty? ? %w[prof trace cover] : tools
      @exec = exec
      @output = output
    end

    # Returns an executable argv array including enabled `-test.*` flags.
    #
    # A short random suffix is appended to output filenames to reduce collisions across runs.
    #
    # @param cmd [String] command/sub-command argument passed to the Go test binary
    # @param params [Array<String>] additional parameter strings passed after `cmd`
    # @return [Array<String>] argv entries to execute
    def argv(cmd, *params)
      [exec, *flags(cmd), cmd, *parameter_args(params)]
    end

    # Returns an executable command string including enabled `-test.*` flags.
    #
    # @param cmd [String] command/sub-command argument passed to the Go test binary
    # @param params [Array<String>] additional parameter strings passed after `cmd`
    # @return [String] the full command to execute
    def command(cmd, *params)
      Shellwords.join(argv(cmd, *params))
    end

    private

    attr_reader :tools, :exec, :output

    def parameter_args(params)
      params.flatten.compact.flat_map { |p| Shellwords.split(p.to_s) }
    end

    def flags(cmd)
      suffix = SecureRandom.alphanumeric(4)
      m = File.basename(exec, File.extname(exec))
      name = "#{m}-#{cmd}"
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
