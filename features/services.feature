@manual @service
Feature: Services

  Allows us to use an external service and use a client to get a response.

  Scenario: Successfully using of services programatically
    Given I configure nonnative programatically with services
    And I start nonnative
    When I connect to the service
    Then I should have a succesful connection

  Scenario: Successfully using of services through configuration
    Given I configure nonnative through configuration with services
    And I start nonnative
    When I connect to the service
    Then I should have a succesful connection

  Scenario: Successfully using of services and closing connections
    Given I configure nonnative programatically with services
    And I start nonnative
    And I set the proxy for service 'service_1' to 'close_all'
    When I connect to the service
    Then I should receive a connection error from the service
    And I should reset the proxy for service 'service_1'

  Scenario: Proxy for service is not found
    Given I configure nonnative programatically with services
    And I start nonnative
    When I try to find the proxy for service 'non_existent'
    Then I should get a proxy not found error
