@manual @clear
Feature: Configured HTTP proxy servers
  Proxy requests through the configured HTTP proxy server.

  Background:
    Given I configure the system through configuration with servers
    And I start the system

  Scenario Outline: The configured HTTP proxy returns a <kind> response
    When I send a <kind> message to the http proxy server
    Then I should receive a <kind> response from the http proxy server

    Examples:
      | kind       |
      | successful |
      | not found  |
