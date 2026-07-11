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

  Scenario: HTTP client supports HEAD and OPTIONS requests
    Given I configure the system programmatically with servers
    And I start the system
    When I send a HEAD message with the HTTP client to the server
    Then I should receive an HTTP response with an empty body and status 200
    When I send an OPTIONS message with the HTTP client to the server
    Then I should receive an HTTP response with an empty body and status 200

  Scenario: HTTP servers compose mounted services
    Given I configure the system programmatically with a composed HTTP server
    And I start the system
    When I send a root message with the HTTP client to the server
    Then I should receive an HTTP "Hello World!" response
    When I send a mounted message with the HTTP client to the server
    Then I should receive an HTTP "Mounted World!" response

  Scenario: HTTP servers reject empty mount maps
    Given I configure the system programmatically with an empty HTTP server
    When I attempt to start the system
    Then starting the system should raise an error containing "HTTP server requires at least one service mount"

  Scenario: HTTP servers return not found for unknown routes
    Given I configure the system programmatically with servers
    And I start the system
    When I send a not found message with the HTTP client to the servers
    Then I should receive an HTTP not found response

  Scenario: HTTP PATCH returns not found for unknown routes
    Given I configure the system programmatically with servers
    And I start the system
    When I send a not found PATCH message with the HTTP client to the servers
    Then I should receive an HTTP not found response

  Scenario: gRPC servers greet clients
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the gRPC client to the servers
    Then I should receive a gRPC "Hello World!" response

  Scenario: gRPC servers compose application and health handlers
    Given I configure the system programmatically with a composed gRPC server
    And I start the system
    When I send a message with the gRPC client to the server
    Then I should receive a gRPC "Hello World!" response
    And the gRPC health helper should report "test" serving on port 9002

  Scenario: gRPC servers reject empty handler lists
    Given I configure the system programmatically with an empty gRPC server
    When I attempt to start the system
    Then starting the system should raise an error containing "gRPC server requires at least one service handler"

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
