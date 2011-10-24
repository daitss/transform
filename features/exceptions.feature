Feature: exceptions handling

Scenario: file not found
  	Given a non-exist file
	When transforming the file
	Then the status should be 404
	
Scenario: transformation failure
	Given a bad file
	When transforming the file
	Then the status should be 500
