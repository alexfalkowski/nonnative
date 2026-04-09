@manual @clear
Feature: Local HTTP proxy servers
  Preserve request bodies and headers when proxying locally.

  Background:
    Given I configure the system programmatically with a local http proxy server
    And I start the system

  Scenario Outline: The local HTTP proxy forwards <verb> requests end to end
    When I send a "<verb>" request with body "Hello World!" to the local http proxy server
    Then I should receive the "<verb>" request details from the local http proxy server

    Examples:
      | verb   |
      | POST   |
      | PUT    |
      | PATCH  |
      | DELETE |
