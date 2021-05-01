@manual
Feature: Processes

  Allows us to start a process and use a client to get a response.

  Scenario: Successfully starting of processes
    Given I configure nonnative programatically with processes
    And I start nonnative
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response

  Scenario: Successfully starting of processes and closing connections
    Given I configure nonnative programatically with processes
    And I start nonnative
    And I set the proxy for process 'start_1' to 'close_all'
    When I send "test" with the TCP client 'start_1' to the processe
    Then I should receive a connection error for client response with TCP
    And I should reset the proxy for process 'start_1'

  Scenario: Successfully starting of processes and getting invalid data
    Given I configure nonnative programatically with processes
    And I start nonnative
    And I set the proxy for process 'start_1' to 'invalid_data'
    When I send "test" with the TCP client 'start_1' to the processe
    Then I should receive a invalid data that is not "test" for client response with TCP
    And I should reset the proxy for process 'start_1'
