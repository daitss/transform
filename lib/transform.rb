#!/usr/bin/ruby
require 'rubygems'
require 'sinatra'
require 'xml'
require "msgpart"


LOGGERNAME = 'TransformService'
TEMPDIR = '/var/tmp/transform/'

#clean up the temp directory
FileUtils.rm_rf(TEMPDIR)

FileUtils.mkdir(TEMPDIR)

enable :logging

error do
  'Encounter Error ' + env['sinatra.error'].name
end

get '/transform/:id' do |transformID|
  puts "name #{transformID}"
 
  if (params["location"].nil?)
    # return the transformation instructions of the transformation identifier
    result = retrieve(transformID)
    headers 'Content-Type' => 'application/xml'
    puts result
    body result.to_s
  else
    puts "location = " + params["location"]
    url = URI.parse(params["location"].to_s)

    case url.scheme
      when "file"
        @sourcepath = url.path
      when "http"
        resource = Net::HTTP.get_response url
        Tempfile.open("file2transform") do |io|
        io.write resource.body
        io.flush
        @sourcepath = io.path
      end
    else
      throw :halt, [400, "invalid url location type"]
    end

    if (@sourcepath.nil?)
      throw :halt, [400, "invalid url location"]
    end
    
    # make sure the file exist and it's a valid file
    if (File.exist?(@sourcepath) && File.file?(@sourcepath)) then
      retrieve(transformID)
      transform
    else
       throw :halt, [404, "#{@sourcepath} does not exist"]
    end
    
  end
  
  response.finish
end

def retrieve(transformID)
  # retrieve the designated processing instruction from the config file
  config = XML::Document.file(CONFIGFILE)
  transformID.upcase!
  transformation = config.find_first("/transformations/transformation[@ID='#{transformID}']")

  if (transformation == nil)
    throw :halt, [501, "cannot find transformation #{transformID}"]
  end

  #retrieve the transformation instruction
  @instruction = transformation.find_first("//instruction/text()")
  if @instruction.nil?
    throw :halt, [501, "no transformation instruction is defined for #{transformID}"]
  end
  
  @extension = transformation.find_first("//extension/text()")
  if @extension.nil?
    @extension = ""
  end
  
  transformation
end

def transform
  # extract the file name port from the source path
  ext = File.extname(@sourcepath)
  filename = File.basename(@sourcepath, ext)
  # create a directory to hold the transformed files
  FileUtils.makedirs(TEMPDIR + filename)
  outputpath = TEMPDIR + filename + "/" + "transformed" + @extension
  command = @instruction.sub(INPUTFILE, @sourcepath).sub(OUTPUTFILE, outputpath)

  # Log4r::Logger[LOGGERNAME].info command
  # backquote the external program, do the transformation 
  `#{command}`
  if ($? != 0)
    # clean up
    FileUtils.rmdir(TEMPDIR + filename)
    throw :halt, [500, "#{command} failed"]
  end

  # build the response
  tmpfiles = TEMPDIR + filename + "/*"

  # sorted by the numerical order of the file name,
  # mtime only goes to seconds, so can't do this :(   File.mtime(x) <=> File.mtime(y) 
  files = Dir.glob(tmpfiles).sort { |x,y| x =~ /.*?(\d+).*/; xn = $1.to_i; y =~ /.*?(\d+).*/; yn = $1.to_i; xn <=> yn }     

  doc = Document.new
  root = doc.add_element('links')

  host_url = params["HTTP_HOST"].to_s
  files.each do |file|
    resource = "http://" + host_url + "/file" + file
    link = Element.new('link')
    link.add_text(resource)
    root.add_element(link)
  end

  headers 'Content-Type' => 'application/xml'
  body doc
end

