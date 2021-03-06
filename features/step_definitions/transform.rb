require 'xml'
require 'cgi'
abs = FileUtils.pwd
path = 'http://www.fcla.edu/daitss-test/files/'

Given /^a PDF file$/ do
  pending
  @transformID = "PDF_NORM"
  @file = "#{path}tagged.pdf"
end

Given /^a wave file$/ do
  @transformID = "WAVE_NORM"
  @file = "#{path}obj1.wav"
end

Given /^an AVI file$/ do
  @transformID = "AVI_NORM"
  @file = "#{path}video.avi"
end

Given /^a quicktime file$/ do
  @transformID = "MOV_NORM"
  @file = "#{path}thesis.mov"
end

Given /^a non\-exist file$/ do
  @transformID = "WAVE_NORM"
  @file = "file://#{abs}/test-files/GLA.tes"
end

Given /^a bad file$/ do
  @transformID = "WAVE_NORM"
  @file = "#{path}tagged.pdf"
end

Given /^a valid transformation$/ do
  @transformID = "WAVE_NORM"
  @file = "#{path}obj1.wav"
end

Given /^a invalid transformation$/ do
  @transformID = "BOGUS_NORM"
end

When /^transforming the file$/ do
  get "/transform/#{@transformID}", :location => @file
end

When /^retrieving the processing instruction$/ do
  get "/transform/#{@transformID}", :location => @file
end

Then /^I should receive (.+?) link to transformed file$/ do |num|  
  doc = XML::Document.string(last_response.body)

  # make sure there are expected number of bitstream objects
  @list = doc.find("//premis:link", 'premis' => 'http://www.loc.gov/premis/v3')
  i = 0
  @list.each {|n| i = i+1 }
  i.should == num.to_i
end

Then /^the transformed file should be received via the link$/ do
  @list.each do |node|
    newurl = node.content
    # chop off the relative path portion
    newurl[".."] = ""
    get newurl
  end
end

Then /^I should receive an xml with the detail processing instructions$/ do
  doc = last_response.body
  doc.should_not be_nil
end

Then /^the status should be (.+?)$/ do |code|
  puts last_response.status

  last_response.status.should eq(code.to_i)
end

