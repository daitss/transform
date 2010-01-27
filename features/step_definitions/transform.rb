require 'xml'
abs = "/Users/Carol/Workspace/daitss2/describe/trunk"

Given /^a PDF file$/ do
  @transformID = "PDF_NORM"
  @file = "file://#{abs}/files/tagged.pdf"
end

Given /^a wave file$/ do
  @transformID = "WAVE_NORM"
  @file = "file://#{abs}/files/GLASS.WAV"
end

Given /^an AVI file$/ do
  @transformID = "AVI_NORM"
  @file = "file://#{abs}/files/video.avi"
end

Given /^a quicktime file$/ do
  @transformID = "MOV_NORM"
  @file = "file://#{abs}/files/thesis.mov"
end

When /^transforming the file$/ do
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
    get node.content
    last_response.status.should == 200
  end
end

Then /^the status should be ok$/ do
  last_response.status.should == 200
end

