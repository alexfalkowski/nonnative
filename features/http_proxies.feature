@acceptance @proxy @manual @clear
Feature: HTTP proxies
  Proxy HTTP requests through local and configured proxy servers.

  Scenario Outline: The local HTTP proxy forwards <verb> requests end to end
    Given I configure the system programmatically with a local HTTP proxy server
    And I start the system
    When I send a "<verb>" request with body "Hello World!" to the local HTTP proxy server
    Then I should receive the "<verb>" request details from the local HTTP proxy server

    Examples:
      | verb   |
      | POST   |
      | PUT    |
      | PATCH  |
      | DELETE |

  Scenario: The local HTTP proxy does not forward proxy credentials
    Given I configure the system programmatically with a local HTTP proxy server
    And I start the system
    When I send a "POST" request with proxy credentials to the local HTTP proxy server
    Then I should receive request details without proxy credentials from the local HTTP proxy server

  Scenario: The local HTTP proxy preserves safe upstream response headers
    Given I configure the system programmatically with a local HTTP proxy server
    And I start the system
    When I request response metadata through the local HTTP proxy server
    Then I should receive preserved response metadata from the local HTTP proxy server

  Scenario: The local HTTP proxy forwards HEAD requests as HEAD
    Given I configure the system programmatically with a local HTTP proxy server
    And I start the system
    When I send a HEAD request to the local HTTP proxy server
    Then I should receive a successful response from the local HTTP proxy server

  Scenario: The local HTTP proxy preserves safe upstream response headers for OPTIONS requests
    Given I configure the system programmatically with a local HTTP proxy server
    And I start the system
    When I request response metadata with an OPTIONS request through the local HTTP proxy server
    Then I should receive preserved response metadata from the local HTTP proxy server

  @config
  Scenario Outline: The configured HTTP proxy returns a <kind> response
    Given I configure the system through configuration with servers
    And I start the system
    When I send a <kind> message to the HTTP proxy server
    Then I should receive a <kind> response from the HTTP proxy server

    Examples:
      | kind       |
      | successful |
      | not found  |
