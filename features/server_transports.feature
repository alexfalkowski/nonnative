@acceptance @manual @clear
Feature: Server transports
  Start configured servers and serve traffic over each supported protocol.

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
    When I send a message with the http client to the servers
    Then I should receive a http "Hello World!" response

  Scenario: HTTP servers return not found for unknown routes
    Given I configure the system programmatically with servers
    And I start the system
    When I send a not found message with the http client to the servers
    Then I should receive a http not found response

  Scenario: gRPC servers greet clients
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the grpc client to the servers
    Then I should receive a grpc "Hello World!" response
