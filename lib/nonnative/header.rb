# frozen_string_literal: true

module Nonnative
  class Header
    class << self
      def http_user_agent(user_agent)
        { user_agent: }
      end

      def grpc_user_agent(user_agent)
        { 'grpc.primary_user_agent' => user_agent }
      end

      def auth_basic(credentials)
        { authorization: "Basic #{Base64.strict_encode64(credentials)}" }
      end

      def auth_bearer(token)
        { authorization: "Bearer #{token}" }
      end
    end
  end
end
