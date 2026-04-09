@manual @service @clear
Feature: Service proxies
  Connect to externally managed services through nonnative proxies.

  Scenario Outline: Services stay reachable when configured <source>
    Given I configure the system <source> with services
    And I start the system
    When I connect to the service
    Then I should have a successful connection

    Examples:
      | source                |
      | programmatically      |
      | through configuration |

  @reset
  Scenario: Closing the service proxy interrupts reads
    Given I configure the system programmatically with services
    And I start the system
    And I set the proxy for service 'service_1' to 'close_all'
    When I connect to the service
    And I receive data from the service
    Then I should receive a connection error from the service

  Scenario: Looking up a missing service proxy fails
    Given I configure the system programmatically with services
    And I start the system
    When I try to find the proxy for service 'non_existent'
    Then I should get a proxy not found error
