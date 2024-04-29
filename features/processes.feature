@manual @clear
Feature: Processes

  Allows us to start a process and use a client to get a response.

  Scenario: Successfully starting of processes
    Given I configure the system programatically with processes
    And I start the system
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response
    And I should see a log entry of "test" for process 'start_1'
    And I should see a log entry of "test" in the file "reports/12_321.log"
    And the process 'start_1' should consume less than '40mb' of memory

