@contract
Feature: Token
  Verify signed tokens can be generated for authenticating against services under test.

  Scenario: Generate a JWT token
    Given an Ed25519 private key
    When I generate a "jwt" token for "GET /v1/things" as "user-1"
    Then the token should be verifiable with:
      | iss | iss            |
      | aud | GET /v1/things |
      | sub | user-1         |
      | kid | key-1          |

  Scenario: Generate a PASETO token
    Given an Ed25519 private key
    When I generate a "paseto" token for "GET /v1/things" as "user-1"
    Then the token should be verifiable with:
      | iss | iss            |
      | aud | GET /v1/things |
      | sub | user-1         |
      | kid | key-1          |

  Scenario: Generate an SSH token
    Given an OpenSSH Ed25519 private key
    When I generate a "ssh" token for "GET /v1/things" as "user-1"
    Then the token should be verifiable with:
      | ver | v1             |
      | kid | key-1          |
      | sub | key-1          |
      | aud | GET /v1/things |

  Scenario: Generate a token for an HTTP endpoint
    Given an Ed25519 private key
    When I generate a "jwt" token for the "GET" "/v1/things" endpoint as "user-1"
    Then the token should be verifiable with:
      | aud | GET /v1/things |

  Scenario: Generate a token for a gRPC method
    Given an Ed25519 private key
    When I generate a "jwt" token for the "/health.v1.Health/Check" method as "user-1"
    Then the token should be verifiable with:
      | aud | /health.v1.Health/Check |
