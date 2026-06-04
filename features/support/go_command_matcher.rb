# frozen_string_literal: true

RSpec::Matchers.define :match_go_command do |table|
  match do |parts|
    rows = table.rows_hash
    @parameters = rows['parameters']
    @output = rows['output']
    @executable = rows['executable']
    @command = rows['command']

    @actual_parts = parts
    @flag_parts = go_command_flag_parts(parts)

    first_part_matches?(parts) &&
      command_parts_match?(parts) &&
      flags_match?
  end

  failure_message do
    "expected #{@actual_parts.inspect} to match Go command " \
      "#{@executable} #{@command} with parameters #{@parameters.inspect}"
  end

  def first_part_matches?(parts)
    parts.first == @executable
  end

  def command_parts_match?(parts)
    return command_without_parameters_matches?(parts) if @parameters == ''

    parameter_parts = @parameters.split(',')
    parts.last(parameter_parts.length) == parameter_parts &&
      parts[-(parameter_parts.length + 1)] == @command
  end

  def command_without_parameters_matches?(parts)
    parts.last == @command
  end

  def go_command_flag_parts(parts)
    return parts[1..-2] if @parameters == ''

    parameter_count = @parameters.split(',').length
    parts[1...-(parameter_count + 1)]
  end

  def flags_match?
    @flag_parts.all? { |part| part.include?("#{@output}/#{@executable}-#{@command}") }
  end
end
