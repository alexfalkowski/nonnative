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
  # - `:limit_data` -> {Nonnative::LimitDataSocketPair}
  # - `:slicer` -> {Nonnative::SlicerSocketPair}
  # - `:flaky` -> {Nonnative::FlakySocketPair}
  #
  # @see Nonnative::FaultInjectionProxy
  # @see Nonnative::SocketPair
  # @see Nonnative::CloseAllSocketPair
  # @see Nonnative::ResetPeerSocketPair
  # @see Nonnative::DelaySocketPair
  # @see Nonnative::TimeoutSocketPair
  # @see Nonnative::InvalidDataSocketPair
  # @see Nonnative::BandwidthSocketPair
  # @see Nonnative::LimitDataSocketPair
  # @see Nonnative::SlicerSocketPair
  # @see Nonnative::FlakySocketPair
  class SocketPairFactory
    PAIR_BY_STATE = {
      close_all: CloseAllSocketPair,
      reset_peer: ResetPeerSocketPair,
      delay: DelaySocketPair,
      timeout: TimeoutSocketPair,
      invalid_data: InvalidDataSocketPair,
      bandwidth: BandwidthSocketPair,
      limit_data: LimitDataSocketPair,
      slicer: SlicerSocketPair,
      flaky: FlakySocketPair
    }.freeze
    private_constant :PAIR_BY_STATE

    class << self
      # Creates a socket-pair instance for the given proxy state.
      #
      # @param kind [Symbol] proxy state (e.g. `:none`, `:close_all`, `:reset_peer`, `:delay`, `:timeout`,
      #   `:invalid_data`, `:bandwidth`, `:limit_data`, `:slicer`, `:flaky`)
      # @param proxy [Nonnative::ConfigurationProxy] proxy configuration (host/port/options)
      # @return [Nonnative::SocketPair] a socket-pair implementation instance
      def create(kind, proxy)
        pair = PAIR_BY_STATE.fetch(kind, SocketPair)

        pair.new(proxy)
      end
    end
  end
end
