# frozen_string_literal: true

When('I create a go command with:') do |table|
  rows = table.rows_hash
  @exec_path = Nonnative.go_executable(rows['output'], rows['executable'], rows['command'], rows['parameters'])
end

When('I load the go configuration') do
  Nonnative.configure do |config|
    config.load_file('features/configs/go.yml')
  end

  @exec_path = Nonnative.configuration.processes.first.command.call
end

Then('I should have a valid go command with:') do |table|
  rows = table.rows_hash
  params = rows['parameters']
  output = rows['output']
  exec = rows['executable']
  cmd = rows['command']
  parts = @exec_path.split

  expect(parts.first).to eq(exec)

  if params == ''
    expect(parts.last).to eq(cmd)

    parts = parts[1..parts.length - 2]
  else
    expect(parts[parts.length - 2]).to eq(cmd)
    expect(parts.last).to eq(params)

    parts = parts[1..parts.length - 3]
  end

  parts.each do |p|
    expect(p).to include("#{output}/#{exec}-#{cmd}")
  end
end
