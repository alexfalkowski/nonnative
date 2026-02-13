# frozen_string_literal: true

module Nonnative
  # Raised when a configured runner cannot be found by name.
  #
  # This is typically raised by lookup helpers such as:
  # - {Nonnative::Configuration#process_by_name}
  # - {Nonnative::Pool#process_by_name}
  # - {Nonnative::Pool#server_by_name}
  # - {Nonnative::Pool#service_by_name}
  class NotFoundError < Nonnative::Error
  end
end
