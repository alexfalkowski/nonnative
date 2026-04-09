# frozen_string_literal: true

Given('I configure the system programmatically with a no op server') do
  configure_no_op_server
end

Given('I configure the system programmatically with a no stop server') do
  configure_no_stop_server
end

Given('I configure the system programmatically with a start error server') do
  configure_start_error_server
end

Given('I configure the system programmatically with a fast exiting process') do
  configure_fast_exiting_process
end

Given('I configure the system programmatically with a stop error server') do
  configure_stop_error_server
end

Then('starting the system should happen within an adequate time') do
  expect { Nonnative.start }.to perform_under(2, warmup: 0).sec
end

Then('stopping the system should happen within an adequate time') do
  expect { Nonnative.stop }.to perform_under(2, warmup: 0).sec
end

Then('the port {string} should be closed') do |port|
  wait_for do
    socket = TCPSocket.new('127.0.0.1', port.to_i)
    socket.close

    false
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
    true
  end.to eq(true)
end
