@manual @clear
Feature: Servers

  Allows us to start a server and use a client to get a response.

  Scenario: Successfully starting of TCP servers programatically
    Given I configure the system programatically with servers
    And I start the system
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response

  Scenario: Successfully starting of TCP servers through configuration
    Given I configure the system through configuration with servers
    And I start the system
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response

  Scenario: Successfully starting of HTTP servers programatically
    Given I configure the system programatically with servers
    And I start the system
    When I send a message with the http client to the servers
    Then I should receive a http "Hello World!" response

  Scenario: Successfully starting of HTTP servers programatically with not found message
    Given I configure the system programatically with servers
    And I start the system
    When I send a not found message with the http client to the servers
    Then I should receive a http not found response

  Scenario: Successfully starting of gRPC servers programatically
    Given I configure the system programatically with servers
    And I start the system
    When I send a message with the grpc client to the servers
    Then I should receive a grpc "Hello World!" response

  Scenario: Successfully starting of HTTP servers programatically and getting health
    Given I configure the system programatically with servers
    And I start the system
    When I send a "health" request
    Then I should receive a successful "health" response

  Scenario: Successfully starting of HTTP servers programatically and getting liveness
    Given I configure the system programatically with servers
    And I start the system
    When I send a "liveness" request
    Then I should receive a successful "liveness" response

  Scenario: Successfully starting of HTTP servers programatically and getting readiness
    Given I configure the system programatically with servers
    And I start the system
    When I send a "readiness" request
    Then I should receive a successful "readiness" response

  Scenario: Successfully starting of HTTP servers programatically and getting metrics
    Given I configure the system programatically with servers
    And I start the system
    When I send a "metrics" request
    Then I should receive a successful "metrics" response

