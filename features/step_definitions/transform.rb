require 'xml'
abs = FileUtils.pwd

Given /^a PDF file$/ do
  @transformID = "PDF_NORM"
  @file = "file://#{abs}/test-files/tagged.pdf"
end

Given /^a wave file$/ do
  @transformID = "WAVE_NORM"
  @file = "file://#{abs}/test-files/obj1.wav"
end

Given /^an AVI file$/ do
  @transformID = "AVI_NORM"
  @file = "file://#{abs}/test-files/video.avi"
end

Given /^a quicktime file$/ do
  @transformID = "MOV_NORM"
  @file = "file://#{abs}/test-files/thesis.mov"
end

Given /^a non\-exist file$/ do
  @transformID = "WAVE_NORM"
  @file = "file://#{abs}/test-files/GLA.tes"
end

Given /^a bad pdf$/ do
  @transformID = "PDF_NORM"
  @file = "file://#{abs}/test-files/etd.pdf"
end

Given /^a valid transformation$/ do
  @transformID = "WAVE_NORM"
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
  puts last_response.body
  doc = XML::Document.string(last_response.body)
 
  # make sure there are expected number of bitstream objects
  @list = doc.find("/links/link")
  @list.size.should == num.to_i
end

Then /^the transformed file should be received via the link$/ do
  @list.each do |node|
    puts node.content
    get node.content
    last_response.status.should == 200
  end
end
 
Then /^I should receive an xml with the detail processing instructions$/ do
  doc = XML::Document.string(last_response.body)
  doc.should_not be_nil
end

Then /^the status should be (.+?)$/ do |code|
  last_response.status.should == code.to_i
end

