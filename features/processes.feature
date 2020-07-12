@manual
Feature: Processes

  Allows us to start a server and use a client to get a response.

  Scenario: Successfully starting of processes
    Given I configure nonnative programatically with processes
    And I start nonnative
    When I send "test" with the tcp client to the processes
    Then I should receive a tcp "test" response
