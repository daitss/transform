#!/usr/bin/ruby
require 'rubygems'
require 'sinatra'
require 'XformModule'

LOGGERNAME = 'TransformService'
TEMPDIR = '/var/tmp/transform/'

# clean up the temp directory
FileUtils.rm_rf(TEMPDIR)
FileUtils.mkdir(TEMPDIR)

enable :logging

error do
  'Encounter Error ' + env['sinatra.error'].name
end

get '/transform/:id' do |transformID|
  xform = XformModule.new(TEMPDIR)

  begin
    if (params["location"].nil?)
      # return the transformation instructions of the transformation identifier
      result = xform.retrieve(transformID)
    else
      puts "location = " + params["location"]
      url = URI.parse(params["location"].to_s)

      case url.scheme
      when "file"
        sourcepath = url.path
      when "http"
        resource = Net::HTTP.get_response url
        Tempfile.open("file2transform") do |io|
          io.write resource.body
          io.flush
          sourcepath = io.path
        end
      else
        halt 400, "invalid url location type"
      end

      halt 400, "invalid url location" unless sourcepath

      # make sure the file exist and it's a valid file
      halt 404, "#{@sourcepath} does not exist" unless (File.exist?(sourcepath) && File.file?(sourcepath))
      xform.retrieve(transformID)
      host_url = "http://" + Sinatra::Application.host + ":" + Sinatra::Application.port.to_s
      puts "host: " + host_url
      result = xform.transform(host_url, sourcepath)
    end
  rescue InstructionError => ie
    halt 501, ie.message
  rescue TransformationError => te
    halt 500, te.message
  end
  
  xform = nil
  headers 'Content-Type' => 'application/xml'
  body result.to_s
  response.finish
end

get '/file*' do 
  # get params from request
  path = params[:splat].to_s
  puts "path = " + path

  halt 400, "need to specify the resource" unless path
  # Log4r::Logger[LOGGERNAME].info "path = #{path}"
  if (File.exist?(path) && File.file?(path)) then
    # build the response
    headers 'Content-Type' => "application/octet-stream"
    headers 'Content-Length' => File.size(path)
    fhandle = File.open(path)
    body fhandle.read
    
    # delete the file after a successful GET
    File.delete(path)
    puts "#{path} has been retrieved and deleted"
    # delete the parent directory if it's empty
    if (Dir.entries(File.dirname(path)) == [".", ".."])
      Dir.delete(File.dirname(path))
    end

  else
    halt 410, "#{path} is no longer available"
  end
end

delete '/file*' do
  # get params from request
  path = params[:splat].to_s

  halt 400, "need to specify the resource  to the requested file" unless path
  if (File.exist?(path) && File.file?(path)) then
    File.delete(path)
  else
    halt 410, "#{path} is no longer available"
  end

end


