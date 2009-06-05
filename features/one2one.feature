Feature: transform a file from one format to the other

Scenario: transform a wave file
	Given a wave file
	When transforming the file
	Then I should receive 1 link to transformed file
	And the status should be ok
	And the transformed file should be received via the link

Scenario: transform an AVI file
	Given an AVI file
	When transforming the file
	Then I should receive 1 link to transformed file
	And the status should be ok
	And the transformed file should be received via the link

Scenario: transform a QuickTime file
	Given a quicktime file
	When transforming the file
	Then I should receive 1 link to transformed file
	And the status should be ok
	And the transformed file should be received via the link
