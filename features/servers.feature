@acceptance @manual @clear
Feature: Servers
  Start configured servers and expose observability endpoints.

  Scenario Outline: TCP servers respond when configured <source>
    Given I configure the system <source> with servers
    And I start the system
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response

    Examples:
      | source           |
      | programmatically |

    @config
    Examples:
      | source                |
      | through configuration |

  Scenario: HTTP servers return hello responses
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the HTTP client to the servers
    Then I should receive an HTTP "Hello World!" response

  Scenario: HTTP servers return not found for unknown routes
    Given I configure the system programmatically with servers
    And I start the system
    When I send a not found message with the HTTP client to the servers
    Then I should receive an HTTP not found response

  Scenario: gRPC servers greet clients
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the gRPC client to the servers
    Then I should receive a gRPC "Hello World!" response

  Scenario: The health endpoint reports the servers as healthy
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response
    And I should see "test" as healthy

  Scenario: The health endpoint reports service unavailable as unhealthy
    Given I configure the system programmatically with servers
    And I start the system
    When the health endpoint reports service unavailable
    Then I should see "test" as unhealthy

  Scenario Outline: The <endpoint> endpoint responds successfully
    Given I configure the system programmatically with servers
    And I start the system
    When I send a "<endpoint>" request
    Then I should receive a successful "<endpoint>" response

    Examples:
      | endpoint  |
      | liveness  |
      | readiness |
      | metrics   |

  Scenario: Server runners can be looked up by name
    Given I configure the system programmatically with servers
    And I start the system
    When I look up the server runner "tcp_server_1"
    Then I should find the server runner "tcp_server_1"

  @proxy @contract
  Scenario: Custom proxy kinds can be registered
    When I register a custom proxy kind
    Then the custom proxy kind should resolve to the custom proxy

  @proxy @contract
  Scenario: Unknown proxy kinds are rejected
    When I try to resolve proxy kind "missing"
    Then resolving the proxy kind should fail with an argument error containing "Unsupported proxy kind 'missing'"
