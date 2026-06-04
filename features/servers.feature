@acceptance @manual @clear
Feature: Servers
  Start configured servers, expose observability endpoints, and control server proxies.

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

  @proxy @contract
  Scenario: Custom proxy kinds can be registered
    When I register a custom proxy kind
    Then the custom proxy kind should resolve to the custom proxy

  @proxy @reset
  Scenario: Closing the HTTP proxy breaks metrics requests
    Given I configure the system programmatically with servers
    And I start the system
    And I set the proxy for server 'http_server_1' to 'close_all'
    When I request metrics over HTTP
    Then I should receive a connection error for metrics response with HTTP

  @proxy @reset
  Scenario Outline: HTTP hello requests fail when the proxy is set to <state>
    Given I configure the system programmatically with servers
    And I start the system
    And I set the proxy for server 'http_server_1' to '<state>'
    When I request hello over HTTP
    Then I should receive the <failure> error for hello response with HTTP

    Examples:
      | state        | failure      |
      | delay        | delay        |
      | invalid_data | invalid data |

  @proxy @reset
  Scenario Outline: gRPC greetings fail when the proxy is set to <state>
    Given I configure the system programmatically with servers
    And I start the system
    And I set the proxy for server 'grpc_server_1' to '<state>'
    When I <request>
    Then I should receive the <failure> error for being greeted with gRPC

    Examples:
      | state        | request                               | failure      |
      | close_all    | greet over gRPC                       | connection   |
      | delay        | greet over gRPC with a short deadline | delay        |
      | invalid_data | greet over gRPC                       | invalid data |

  @proxy
  Scenario: Looking up a missing server proxy fails
    Given I configure the system programmatically with servers
    And I start the system
    When I try to find the proxy for server 'non_existent'
    Then I should get a proxy not found error
