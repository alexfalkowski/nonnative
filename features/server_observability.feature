@acceptance @manual @clear
Feature: Server observability
  Expose health and status endpoints for configured servers.

  Background:
    Given I configure the system programmatically with servers
    And I start the system

  Scenario: The health endpoint reports the servers as healthy
    When I send a message with the tcp client to the servers
    Then I should receive a TCP "Hello World!" response
    And I should see "test" as healthy

  Scenario: The health endpoint reports service unavailable as unhealthy
    When the health endpoint reports service unavailable
    Then I should see "test" as unhealthy

  Scenario Outline: The <endpoint> endpoint responds successfully
    When I send a "<endpoint>" request
    Then I should receive a successful "<endpoint>" response

    Examples:
      | endpoint  |
      | liveness  |
      | readiness |
      | metrics   |
