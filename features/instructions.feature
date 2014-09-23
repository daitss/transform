Feature: retrieve processing instructions

Scenario: retrieve defined processing instruction
  	Given a valid transformation
	When retrieving the processing instruction
	Then I should receive an xml with the detail processing instructions
	And the status should be 200
	
Scenario: retrieve undefined processing instruction
	Given a invalid transformation
	When retrieving the processing instruction
	Then the status should be 501
