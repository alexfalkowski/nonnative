@manual
Feature: Servers

  Allows us to start a echo server and use an echo client to get a response.

  Scenario: Successfully starting of servers programatically
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a message with the echo client to the servers
    Then I should receive a "Hello World!" response

   Scenario: Successfully starting of servers through configuration
    Given I configure nonnative through configuration with servers
    And I start nonnative
    When I send a message with the echo client to the servers
    Then I should receive a "Hello World!" response
