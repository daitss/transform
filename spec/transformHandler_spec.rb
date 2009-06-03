require 'transformHandler'
require 'net/http'

describe TransformHandler do

  before(:all) do
    begin
      @server = Mongrel::HttpServer.new("localhost", "3003")
    rescue => ex
      STDERR.puts "Can't start server on #{MHOST}:#{PORT}:  #{ex.message}"
      exit    
    end
    #create and register the describe handler
    @transformhandler = TransformHandler.new('/var/tmp/transform/')
    @server.register("/transform", @transformhandler)    
    @url = 'http://localhost:3003/transform/'
    STDERR.puts "server started"
    @server.run
  end

  after(:all) do
    @server.stop
    STDERR.puts "server stoped"
  end

  def send(method, querystring = nil, data=nil, head=nil)
    url = URI.parse(@url)   
    #puts querystring
    response = Net::HTTP.start(url.host, url.port) {|http|
      unless (querystring.nil?)
        http.send_request(method, url.path + querystring, data, head)
      else
        http.send_request(method, url.path, data, head)
      end
    }
    response
  end

  it "should return 200 for a successful GET on WAVE_NORM transformation information" do
    querystring = "WAVE_NORM"
    response = send("GET", querystring)
    puts response.body
    response.code.to_i.should == 200
  end

  #TODO: revisit
  it "should return 501 for a GET on an invalid transformation" do
    querystring = "BOGUS_NORM"
    response = send("GET", querystring)
    puts response.body
    response.code.to_i.should == 501
  end

  it "should return 200 for a successful GET on WAVE_NORM" do
    querystring = "WAVE_NORM?location=file:///Users/Carol/Workspace/describe/files/GLASS.WAV"
    response = send("GET", querystring)
    #puts response.body
    response.code.to_i.should == 200
  end

  it "should return 200 for a successful GET on PDF_NORM" do
    querystring = "PDF_NORM?location=file:///Users/Carol/Desktop/work/testdata/pdf/movietest.pdf"
    response = send("GET", querystring)
    #puts response.body
    response.code.to_i.should == 200
  end

  it "should return 200 for a successful GET on MOV_NORM" do
    querystring = "MOV_NORM?location=file:///Users/Carol/Desktop/work/testdata/video/mov/mama.mov"
    response = send("GET", querystring)
    #puts response.body
    response.code.to_i.should == 200
  end

  it "should return 200 for a successful GET on AVI_NORM" do
    querystring = "AVI_NORM?location=file:///Users/Carol/Desktop/work/testdata/video/avi/video.avi"
    response = send("GET", querystring)
    #puts response.body
    response.code.to_i.should == 200
  end

  it "should return 404 for file not found" do
    querystring = "WAVE_NORM?location=file:///Users/Carol/Workspace/describe/files/GLA"
    response = send("GET", querystring)
    puts response.body
    response.code.to_i.should == 404
  end

  #TODO revisit
  it "should return 501 for unknown processing instruction" do
    querystring = "BAD_NORM?location=file:///Users/Carol/Workspace/describe/files/GLASS.WAV"
    response = send("GET", querystring)
    puts response.body
    response.code.to_i.should == 501
  end

  it "should return 500 for transformation failure" do
    querystring = "WAVE_NORM?location=file:///Users/Carol/Workspace/describe/files/etd.pdf"
    response = send("GET", querystring)
    puts response.body
    response.code.to_i.should == 500
  end

  #todo: implement put
  it "it should return 405 for PUT" do  
    response = send("PUT", nil, nil)
    puts response.body
    response.code.to_i.should == 405
  end

  it "should return 405 for unsupported DELETE method" do
    response = send("DELETE")
    puts response.body
    response.code.to_i.should == 405
  end

  it "should return 405 for unsupported POST method" do
    response = send("POST")
    puts response.body
    response.code.to_i.should == 405
  end

  #todo: may implement HEAD to return agent information
  it "should return 405 for unsupported HEAD method" do
    response = send("HEAD")
    puts response.body
    response.code.to_i.should == 405
  end

  it "should return 405 for bogus method" do
    response = send("TEST")
    puts response.body
    response.code.to_i.should == 405
  end

  it "should return 505 if not in HTTP/1.1" do   
    response = send("GET", nil, nil, { 'Version' => 'HTTP/1.0' })
    response.code.to_i.should == 505
  end

end
