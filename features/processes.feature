@acceptance @manual @clear
Feature: Process runners
  Start managed processes and exercise their client-facing TCP endpoints.

  Scenario Outline: Processes echo TCP messages when configured <source>
    Given I configure the system <source> with processes
    And I start the system
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response

    Examples:
      | source           |
      | programmatically |

    @config
    Examples:
      | source                |
      | through configuration |

  Scenario: Process activity is logged and stays within the memory budget
    Given I configure the system programmatically with processes
    And I start the system
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response
    And I should see a log entry of "test" for process 'start_1'
    And I should see a log entry of "test" in the file "test/reports/12_321.log"
    And the process 'start_1' should consume less than '40mb' of memory

  @proxy @reset
  Scenario: A delayed process proxy still allows TCP responses
    Given I configure the system programmatically with processes
    And I start the system
    And I set the proxy for process 'start_1' to 'delay'
    When I send "test" with the TCP client to the processes
    Then I should receive a TCP "test" response

  @proxy @reset
  Scenario: Closing the process proxy resets the TCP client
    Given I configure the system programmatically with processes
    And I start the system
    And I set the proxy for process 'start_1' to 'close_all'
    When I send "test" with the TCP client 'start_1' to the process
    Then I should receive a connection error for client response with TCP

  @proxy @reset
  Scenario: Invalid proxy data changes the TCP client response
    Given I configure the system programmatically with processes
    And I start the system
    And I set the proxy for process 'start_1' to 'invalid_data'
    When I send "test" with the TCP client 'start_1' to the process
    Then I should receive a invalid data that is not "test" for client response with TCP

  @proxy
  Scenario: Looking up a missing process proxy fails
    Given I configure the system programmatically with processes
    And I start the system
    When I try to find the proxy for process 'non_existent'
    Then I should get a proxy not found error
