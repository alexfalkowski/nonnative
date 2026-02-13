# frozen_string_literal: true

module Nonnative
  # Factory for creating socket-pair implementations used by {Nonnative::FaultInjectionProxy}.
  #
  # A socket-pair is responsible for wiring a local accepted socket to a remote upstream socket,
  # optionally injecting failures (close connections, add delays, corrupt data, etc).
  #
  # Proxy states are mapped as follows:
  # - `:none` (or any unknown value) -> {Nonnative::SocketPair} (pass-through)
  # - `:close_all` -> {Nonnative::CloseAllSocketPair}
  # - `:delay` -> {Nonnative::DelaySocketPair}
  # - `:invalid_data` -> {Nonnative::InvalidDataSocketPair}
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPair
  # @see Nonnative::CloseAllSocketPair
  # @see Nonnative::DelaySocketPair
  # @see Nonnative::InvalidDataSocketPair
  class SocketPairFactory
    class << self
      # Creates a socket-pair instance for the given proxy state.
      #
      # @param kind [Symbol] proxy state (e.g. `:none`, `:close_all`, `:delay`, `:invalid_data`)
      # @param proxy [Nonnative::ConfigurationProxy] proxy configuration (host/port/options)
      # @return [Nonnative::SocketPair] a socket-pair implementation instance
      def create(kind, proxy)
        pair = case kind
               when :close_all
                 CloseAllSocketPair
               when :delay
                 DelaySocketPair
               when :invalid_data
                 InvalidDataSocketPair
               else
                 SocketPair
               end

        pair.new(proxy)
      end
    end
  end
end
