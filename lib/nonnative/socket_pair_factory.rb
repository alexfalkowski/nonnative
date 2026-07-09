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
  # - `:reset_peer` -> {Nonnative::ResetPeerSocketPair}
  # - `:delay` -> {Nonnative::DelaySocketPair}
  # - `:timeout` -> {Nonnative::TimeoutSocketPair}
  # - `:invalid_data` -> {Nonnative::InvalidDataSocketPair}
  # - `:bandwidth` -> {Nonnative::BandwidthSocketPair}
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPair
  # @see Nonnative::CloseAllSocketPair
  # @see Nonnative::ResetPeerSocketPair
  # @see Nonnative::DelaySocketPair
  # @see Nonnative::TimeoutSocketPair
  # @see Nonnative::InvalidDataSocketPair
  # @see Nonnative::BandwidthSocketPair
  class SocketPairFactory
    class << self
      # Creates a socket-pair instance for the given proxy state.
      #
      # @param kind [Symbol] proxy state (e.g. `:none`, `:close_all`, `:reset_peer`, `:delay`, `:timeout`, `:invalid_data`, `:bandwidth`)
      # @param proxy [Nonnative::ConfigurationProxy] proxy configuration (host/port/options)
      # @return [Nonnative::SocketPair] a socket-pair implementation instance
      def create(kind, proxy)
        pair = case kind
               when :close_all
                 CloseAllSocketPair
               when :reset_peer
                 ResetPeerSocketPair
               when :delay
                 DelaySocketPair
               when :timeout
                 TimeoutSocketPair
               when :invalid_data
                 InvalidDataSocketPair
               when :bandwidth
                 BandwidthSocketPair
               else
                 SocketPair
               end

        pair.new(proxy)
      end
    end
  end
end
