@contract @clear
Feature: Command
  Verify commands are formatted correctly when they run.

  Scenario: Go argv with parameters
    When I create a go argv with:
      | output     | reports          |
      | executable | thisshouldbelong |
      | command    | server           |
      | parameters | --level=info     |
    Then I should have a valid go command argv with:
      | output     | reports          |
      | executable | thisshouldbelong |
      | command    | server           |
      | parameters | --level=info     |

  Scenario: Go argv with shell-style parameter words
    When I create a go argv with:
      | output     | reports                    |
      | executable | thisshouldbelong           |
      | command    | server                     |
      | parameters | -i file:.config/server.yml |
    Then I should have a valid go command argv with:
      | output     | reports                    |
      | executable | thisshouldbelong           |
      | command    | server                     |
      | parameters | -i,file:.config/server.yml |

  Scenario: Go command string
    When I create a go command string with:
      | output     | reports                    |
      | executable | thisshouldbelong           |
      | command    | client                     |
      | parameters | -i,file:.config/client.yml |
    Then I should have a valid go command string with:
      | output     | reports                    |
      | executable | thisshouldbelong           |
      | command    | client                     |
      | parameters | -i,file:.config/client.yml |

  Scenario: Go argv without parameters
    When I create a go argv with:
      | output     | reports          |
      | executable | thisshouldbelong |
      | command    | server           |
      | parameters |                  |
    Then I should have a valid go command argv with:
      | output     | reports          |
      | executable | thisshouldbelong |
      | command    | server           |
      | parameters |                  |

  @config
  Scenario: Go command from configuration
    When I load the go configuration
    Then I should have a valid go command argv with:
      | output     | reports          |
      | executable | thisshouldbelong |
      | command    | server           |
      | parameters | --level=info     |
