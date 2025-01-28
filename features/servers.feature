@manual @clear
Feature: Servers
  Allows us to start a server and use a client to get a response.

  Scenario: Successfully starting of TCP servers programmatically
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response
    And I should see "test" as healthy

  Scenario: Successfully starting of TCP servers through configuration
    Given I configure the system through configuration with servers
    And I start the system
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response

  Scenario: Successfully starting of HTTP servers programmatically
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the http client to the servers
    Then I should receive a http "Hello World!" response

  Scenario: Successfully starting of HTTP proxy servers through configuration
    Given I configure the system through configuration with servers
    And I start the system
    When I send a succesful message to the http proxy server
    Then I should receive a successful response from the http proxy server

  Scenario: Successfully starting of HTTP proxy servers through configuration with a not found response
    Given I configure the system through configuration with servers
    And I start the system
    When I send a not found message to the http proxy server
    Then I should receive a not found response from the http proxy server

  Scenario: Successfully starting of HTTP servers programmatically with not found message
    Given I configure the system programmatically with servers
    And I start the system
    When I send a not found message with the http client to the servers
    Then I should receive a http not found response

  Scenario: Successfully starting of gRPC servers programmatically
    Given I configure the system programmatically with servers
    And I start the system
    When I send a message with the grpc client to the servers
    Then I should receive a grpc "Hello World!" response

  Scenario: Successfully starting of HTTP servers programmatically and getting health
    Given I configure the system programmatically with servers
    And I start the system
    When I send a "health" request
    Then I should receive a successful "health" response

  Scenario: Successfully starting of HTTP servers programmatically and getting liveness
    Given I configure the system programmatically with servers
    And I start the system
    When I send a "liveness" request
    Then I should receive a successful "liveness" response

  Scenario: Successfully starting of HTTP servers programmatically and getting readiness
    Given I configure the system programmatically with servers
    And I start the system
    When I send a "readiness" request
    Then I should receive a successful "readiness" response

  Scenario: Successfully starting of HTTP servers programmatically and getting metrics
    Given I configure the system programmatically with servers
    And I start the system
    When I send a "metrics" request
    Then I should receive a successful "metrics" response

  Scenario: Successfully starting of HTTP servers programmatically and closing connections while getting metrics
    Given I configure the system programmatically with servers
    And I start the system
    When I set the proxy for server 'http_server_1' to 'close_all'
    Then I should receive a connection error for metrics response with HTTP
    And I should reset the proxy for server 'http_server_1'

  Scenario: Successfully starting of HTTP servers programmatically and delaying connections while getting hello
    Given I configure the system programmatically with servers
    And I start the system
    When I set the proxy for server 'http_server_1' to 'delay'
    Then I should receive a delay error for hello response with HTTP
    And I should reset the proxy for server 'http_server_1'

  Scenario: Successfully starting of HTTP servers programmatically and sending invalid data while getting hello
    Given I configure the system programmatically with servers
    And I start the system
    When I set the proxy for server 'http_server_1' to 'invalid_data'
    Then I should receive a invalid data error for hello response with HTTP
    And I should reset the proxy for server 'http_server_1'

  Scenario: Successfully starting of gRPC servers programmatically and closing connections while getting greeted
    Given I configure the system programmatically with servers
    And I start the system
    When I set the proxy for server 'grpc_server_1' to 'close_all'
    Then I should receive a connection error for being greeted with gRPC
    And I should reset the proxy for server 'grpc_server_1'

  Scenario: Successfully starting of gRCP servers programmatically and delaying connections while getting greeted
    Given I configure the system programmatically with servers
    And I start the system
    When I set the proxy for server 'grpc_server_1' to 'delay'
    Then I should receive a delay error for being greeted with gRPC
    And I should reset the proxy for server 'grpc_server_1'

  Scenario: Successfully starting of gRPC servers programmatically and sending invalid data while getting greeted
    Given I configure the system programmatically with servers
    And I start the system
    When I set the proxy for server 'grpc_server_1' to 'invalid_data'
    Then I should receive a invalid data error for being greeted with gRPC
    And I should reset the proxy for server 'grpc_server_1'

  Scenario: Proxy for server is not found
    Given I configure the system programmatically with servers
    And I start the system
    When I try to find the proxy for server 'non_existent'
    Then I should get a proxy not found error
