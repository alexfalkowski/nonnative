@manual @clear
Feature: Server proxy control
  Use fault-injection proxies in front of servers.

  Background:
    Given I configure the system programmatically with servers
    And I start the system

  @reset
  Scenario: Closing the HTTP proxy breaks metrics requests
    And I set the proxy for server 'http_server_1' to 'close_all'
    When I request metrics over HTTP
    Then I should receive a connection error for metrics response with HTTP

  @reset
  Scenario Outline: HTTP hello requests fail when the proxy is set to <state>
    And I set the proxy for server 'http_server_1' to '<state>'
    When I request hello over HTTP
    Then I should receive a <failure> error for hello response with HTTP

    Examples:
      | state        | failure      |
      | delay        | delay        |
      | invalid_data | invalid data |

  @reset
  Scenario Outline: gRPC greetings fail when the proxy is set to <state>
    And I set the proxy for server 'grpc_server_1' to '<state>'
    When I <request>
    Then I should receive a <failure> error for being greeted with gRPC

    Examples:
      | state        | request                               | failure      |
      | close_all    | greet over gRPC                       | connection   |
      | delay        | greet over gRPC with a short deadline | delay        |
      | invalid_data | greet over gRPC                       | invalid data |

  Scenario: Looking up a missing server proxy fails
    When I try to find the proxy for server 'non_existent'
    Then I should get a proxy not found error
