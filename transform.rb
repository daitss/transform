#!/usr/bin/ruby

require 'rubygems'
require 'sinatra'
require 'erb'

$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'XformModule'

LOGGERNAME = 'TransformService'

class Transform < Sinatra::Base
  enable :logging
  set :root, File.dirname(__FILE__)

  configure do
    # create a unique temporary directory to hold the output files.
    tf = Tempfile.new("transform") 

    $tempdir = tf.path
    tf.close!
    puts $tempdir
    FileUtils.mkdir($tempdir)
  end
  
  error do
    'Encounter Error ' + env['sinatra.error'].name
  end

  get '/transform/:id' do |transformID|
    xform = XformModule.new($tempdir)

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

        @result = xform.transform(sourcepath)
        @agentId =  xform.identifier
        @agentNote = xform.software
      end
    rescue InstructionError => ie
      halt 501, ie.message
    rescue TransformationError => te
      halt 500, te.message
    end

    # dump the xml output to the response
    headers 'Content-Type' => 'application/xml'
    body erb(:result)
    xform = nil
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

  at_exit do 
    puts "SHUTTING DOWN!, deleting #{$tempdir}" 
    FileUtils.remove_dir($tempdir)
  end
end

Transform.run! if __FILE__ == $0

