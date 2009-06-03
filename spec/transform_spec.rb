require 'transform'
require 'spec'
require 'spec/interop/test'
require 'sinatra/test'

describe 'Transform Service' do
  include Sinatra::Test

  before(:all) do
      @url = '/transform'
    end

  it "should return 200 for a successful GET on WAVE_NORM transformation information" do
    get "/transform/WAVE_NORM"
    response.should be_ok
  end

  it "should return 501 for a GET on an invalid transformation" do
    get "/transform/BOGUS_NORM"
    response.status.should == 501
  end

  it "should return 200 for a successful GET on WAVE_NORM" do
    get "/transform/WAVE_NORM?location=file:///Users/Carol/Workspace/daitss2/describe/trunk/files/GLASS.WAV"
    response.should be_ok
  end

  it "should return 200 for a successful GET on PDF_NORM" do
    get "/transform/PDF_NORM?location=file:///Users/Carol/Desktop/work/testdata/pdf/movietest.pdf"
    response.should be_ok
  end

  it "should return 200 for a successful GET on MOV_NORM" do
    get "/transform/MOV_NORM?location=file:///Users/Carol/Desktop/work/testdata/video/mov/mama.mov"
    response.should be_ok
  end

  it "should return 200 for a successful GET on AVI_NORM" do
    get "/transform/AVI_NORM?location=file:///Users/Carol/Desktop/work/testdata/video/avi/video.avi"
    response.should be_ok
  end

  it "should return 404 for file not found" do
    get "/transform/WAVE_NORM?location=file:///Users/Carol/Workspace/describe/files/GLA"
    response.status.should == 404
  end

  it "should return 501 for unknown processing instruction" do
    get "/transform/BAD_NORM?location=file:///Users/Carol/Workspace/daitss2/describe/trunk/files/GLASS.WAV"
    response.status.should == 501
  end

  it "should return 500 for transformation failure" do
    get "/transform/WAVE_NORM?location=file:///Users/Carol/Workspace/daitss2/describe/trunk/files/etd.pdf"
    response.status.should == 500
  end

end
