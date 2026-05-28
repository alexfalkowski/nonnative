@acceptance @proxy @manual @clear
Feature: HTTP proxies
  Proxy HTTP requests through local and configured proxy servers.

  Scenario Outline: The local HTTP proxy forwards <verb> requests end to end
    Given I configure the system programmatically with a local http proxy server
    And I start the system
    When I send a "<verb>" request with body "Hello World!" to the local http proxy server
    Then I should receive the "<verb>" request details from the local http proxy server

    Examples:
      | verb   |
      | POST   |
      | PUT    |
      | PATCH  |
      | DELETE |

  @config
  Scenario Outline: The configured HTTP proxy returns a <kind> response
    Given I configure the system through configuration with servers
    And I start the system
    When I send a <kind> message to the http proxy server
    Then I should receive a <kind> response from the http proxy server

    Examples:
      | kind       |
      | successful |
      | not found  |
