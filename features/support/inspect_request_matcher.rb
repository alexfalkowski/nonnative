# frozen_string_literal: true

RSpec::Matchers.define :match_inspected_proxy_request do |verb, expected_body|
  match do |body|
    @verb = verb
    @expected_body = expected_body
    @body = body

    body_matches? && headers_match?
  end

  failure_message do
    "expected #{@body.inspect} to match inspected #{@verb} request with body #{@expected_body.inspect}"
  end

  def body_matches?
    expected_fields = {
      'method' => @verb,
      'body' => @expected_body,
      'content_type' => 'application/json',
      'content_length' => @expected_body.length.to_s
    }

    includes_fields?(expected_fields)
  end

  def headers_match?
    includes_fields?(expected_inspect_headers)
  end

  def includes_fields?(fields)
    fields.all? { |key, value| @body[key] == value }
  end

  def expected_inspect_headers
    case @verb
    when 'POST'
      { 'authorization' => Nonnative::Header.auth_basic('test:test').fetch(:authorization) }
    when 'PUT', 'DELETE'
      { 'authorization' => Nonnative::Header.auth_bearer('token').fetch(:authorization) }
    when 'PATCH'
      { 'user_agent' => Nonnative::Header.http_user_agent('test 1.0').fetch(:user_agent) }
    else
      {}
    end
  end
end
