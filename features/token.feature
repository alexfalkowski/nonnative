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

  Scenario: Generate a not-yet-valid JWT with independent time claims
    Given an Ed25519 private key
    When I generate a "jwt" token with:
      | issued_at  | 4102444800 |
      | not_before | 4102448400 |
      | expires_at | 4102452000 |
    Then the token time claims should be:
      | iat | 4102444800 |
      | nbf | 4102448400 |
      | exp | 4102452000 |

  Scenario: Generate a not-yet-valid PASETO with independent time claims
    Given an Ed25519 private key
    When I generate a "paseto" token with:
      | issued_at  | 4102444800 |
      | not_before | 4102448400 |
      | expires_at | 4102452000 |
    Then the token time claims should be:
      | iat | 4102444800 |
      | nbf | 4102448400 |
      | exp | 4102452000 |

  Scenario: Generate an SSH token with independent time claims
    Given an OpenSSH Ed25519 private key
    When I generate a "ssh" token with:
      | issued_at  | 4102444800 |
      | expires_at | 4102452000 |
    Then the token time claims should be:
      | iat | 4102444800 |
      | exp | 4102452000 |

  Scenario: SSH tokens reject a not-before override
    Given an OpenSSH Ed25519 private key
    When I try to generate a "ssh" token with:
      | not_before | 4102448400 |
    Then token generation should fail with "ssh tokens do not support"
