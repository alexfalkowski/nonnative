@manual
Feature: Servers

  Allows us to start a server and use a client to get a response.

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

  Scenario: Successfully starting of HTTP servers programatically with not found message
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a not found message with the http client to the servers
    Then I should receive a http not found response

  Scenario: Successfully starting of gRPC servers programatically
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a message with the grpc client to the servers
    Then I should receive a grpc "Hello World!" response

  Scenario: Successfully starting of HTTP servers programatically and getting health
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a health request
    Then I should receive a successful health response

  Scenario: Successfully starting of HTTP servers programatically and getting metrics
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I send a metrics request
    Then I should receive a successful metrics response

  Scenario: Successfully starting of HTTP servers programatically and closing connections while getting metrics
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I set the proxy for server 'http_server_1' to 'close_all'
    Then I should receive a connection error for metrics response
    And I should reset the proxy for server 'http_server_1'

  Scenario: Successfully starting of HTTP servers programatically and delaying connections while getting hello
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I set the proxy for server 'http_server_1' to 'delay'
    Then I should receive a delay error for hello response
    And I should reset the proxy for server 'http_server_1'

  Scenario: Successfully starting of HTTP servers programatically and sending invalid data while getting hello
    Given I configure nonnative programatically with servers
    And I start nonnative
    When I set the proxy for server 'http_server_1' to 'invalid_data'
    Then I should receive a invalid data error for hello response
    And I should reset the proxy for server 'http_server_1'
