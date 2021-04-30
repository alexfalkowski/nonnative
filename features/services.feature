@manual @service
Feature: Services

  Allows us to use an external service and use a client to get a response.

  Scenario: Successfully using of services
    Given I configure nonnative programatically with services
    And I start nonnative
    When I connect to the service
    Then I should have a succesful connection

  Scenario: Successfully using of services and closing connections
    Given I configure nonnative programatically with services
    And I start nonnative
    When I set the proxy for service 'service_1' to 'close_all'
    When I connect to the service
    Then I should receive a connection error from the service
    And I should reset the proxy for service 'service_1'
