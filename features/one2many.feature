Feature: transform a file from one format to the other which results in multiple files

Scenario: transform a PDF file
	Given a PDF file
	When transforming the file
	Then I should receive 55 link to transformed file
	And the status should be ok
	And the transformed file should be received via the link
