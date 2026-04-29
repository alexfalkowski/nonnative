@contract @proxy @clear
Feature: Proxy contracts
  Preserve proxy extension and control behavior.

  Scenario: Custom proxy kinds can be registered
    When I register a custom proxy kind
    Then the custom proxy kind should resolve to the custom proxy
