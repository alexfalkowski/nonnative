@manual
Feature: Servers

  Allows us to start a echo server and use an echo client to get a response.

  Scenario: Successfully starting of TCP servers programatically
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a message with the tcp client to the servers
    Then I should receive a tcp "Hello World!" response

  Scenario: Successfully starting of TCP servers through configuration
    Given I configure nonnative through configuration with servers
    And I start nonnative
    When I send a message with the tcp client to the servers
    Then I should receive a tcp "Hello World!" response

  Scenario: Successfully starting of HTTP servers programatically
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a message with the http client to the servers
    Then I should receive a http "Hello World!" response

  Scenario: Successfully starting of gRPC servers programatically
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a message with the grpc client to the servers
    Then I should receive a grpc "Hello World!" response

  Scenario: Successfully starting of HTTP servers programatically and getting health
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a message a health request
    Then I should receive a successful health response
