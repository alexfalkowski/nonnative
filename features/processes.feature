@manual @clear
Feature: Processes
  Allows us to start a process and use a client to get a response.

  Scenario: Successfully starting of processes
    Given I configure the system programmatically with processes
    And I start the system
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response
    And I should see a log entry of "test" for process 'start_1'
    And I should see a log entry of "test" in the file "test/reports/12_321.log"
    And the process 'start_1' should consume less than '40mb' of memory

  @reset
  Scenario: Successfully starting of processes with delay
    Given I configure the system programmatically with processes
    And I start the system
    And I set the proxy for process 'start_1' to 'delay'
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response
    And I should see a log entry of "test" for process 'start_1'
    And I should see a log entry of "test" in the file "test/reports/12_321.log"
    And the process 'start_1' should consume less than '40mb' of memory
    And I should reset the proxy for process 'start_1'

  @reset
  Scenario: Successfully starting of processes and closing connections
    Given I configure the system programmatically with processes
    And I start the system
    And I set the proxy for process 'start_1' to 'close_all'
    When I send "test" with the TCP client 'start_1' to the process
    Then I should receive a connection error for client response with TCP
    And I should reset the proxy for process 'start_1'

  @reset
  Scenario: Successfully starting of processes and getting invalid data
    Given I configure the system programmatically with processes
    And I start the system
    And I set the proxy for process 'start_1' to 'invalid_data'
    When I send "test" with the TCP client 'start_1' to the process
    Then I should receive a invalid data that is not "test" for client response with TCP
    And I should reset the proxy for process 'start_1'

  Scenario: Proxy for process is not found
    Given I configure the system programmatically with processes
    And I start the system
    When I try to find the proxy for process 'non_existent'
    Then I should get a proxy not found error
