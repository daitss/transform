#!/usr/bin/ruby

require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'erb'
require 'cgi'
require 'net/http'

require 'datyl/logger'
require 'datyl/config'


$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'XformModule'

include Datyl

config = nil

def get_config
  raise "No DAITSS_CONFIG environment variable has been set, so there's no configuration file to read"             unless ENV['DAITSS_CONFIG']
  raise "The DAITSS_CONFIG environment variable points to a non-existant file, (#{ENV['DAITSS_CONFIG']})"          unless File.exists? ENV['DAITSS_CONFIG']
  raise "The DAITSS_CONFIG environment variable points to a directory instead of a file (#{ENV['DAITSS_CONFIG']})"     if File.directory? ENV['DAITSS_CONFIG']
  raise "The DAITSS_CONFIG environment variable points to an unreadable file (#{ENV['DAITSS_CONFIG']})"            unless File.readable? ENV['DAITSS_CONFIG']

  Datyl::Config.new(ENV['DAITSS_CONFIG'], :defaults, ENV['VIRTUAL_HOSTNAME'])
end

configure do
  config = get_config

  # create a unique temporary directory to hold the output files.
  $tempdir = Dir.mktmpdir
  # puts "create #{$tempdir}"
  
  disable :logging        # Stop CommonLogger from logging to STDERR; we'll set it up ourselves.

  disable :dump_errors    # Normally set to true in 'classic' style apps (of which this is one) regardless of :environment; it adds a backtrace to STDERR on all raised errors (even those we properly handle). Not so good.

  set :environment,  :production  # Get some exceptional defaults.

  set :raise_errors, false        # Handle our own exceptions.

  Datyl::Logger.setup('Transform', ENV['VIRTUAL_HOSTNAME'])

  if not (config.log_syslog_facility or config.log_filename)
    Datyl::Logger.stderr # log to STDERR
  end

  Datyl::Logger.facility = config.log_syslog_facility if config.log_syslog_facility
  Datyl::Logger.filename = config.log_filename if config.log_filename

  Datyl::Logger.info "Starting up transform service"
  Datyl::Logger.info "Using temp directory #{ENV['TMPDIR']}"

  use Rack::CommonLogger, Datyl::Logger.new(:info, 'Rack:')
  
end

error do
  e = @env['sinatra.error']
  Datyl::Logger.err "Caught Error"
  request.body.rewind if request.body.respond_to?('rewind') # work around for verbose passenger warning

  Datyl::Logger.err "Caught exception #{e.class}: '#{e.message}'; backtrace follows", @env
  e.backtrace.each { |line| Datyl::Logger.err line, @env }

  halt 500, { 'Content-Type' => 'text/plain' }, e.message + "\n"
end

not_found do
  request.body.rewind if request.body.respond_to?(:rewind)

  content_type 'text/plain'  
  "Not Found\n"
end


# Give a file to the transformation service to convert the file based on the transformID
get '/transform/:id' do |transformID|
  halt 400, "missing parameter location='@filename'" unless params['location']
  xform = XformModule.new($tempdir, config)
  sourcepath = nil
  begin
    Datyl::Logger.info "location = " + params["location"]
    url = URI.parse(params["location"].to_s)

    case url.scheme
      when "file"
        sourcepath = url.path
      when "http"
        resource = Net::HTTP.get_response url
        index = url.path.rindex('.')
        file_ext = url.path.slice(index, url.path.length) if index
        io = Tempfile.new(['file2describe', file_ext])
        io.write resource.body
        io.flush
        sourcepath = io.path
        io.close
      else
        Datyl::Logger.err "invalid url location type"
        halt 400, "invalid url location type"
    end

    unless sourcepath
      Datyl::Logger.err "invalid url location"
      halt 400, "invalid url location"
    end

    # make sure the file exist and it's a valid file
    unless (File.exist?(sourcepath) && File.file?(sourcepath))
      Datyl::Logger.err "#{@sourcepath} does not exist"
      halt 404, "#{@sourcepath} does not exist"
    end

    @event_outcome = "success"   
    xform.retrieve(transformID)
    @result = xform.transform(sourcepath) if sourcepath
    @agentId =  xform.identifier
    @agentNote = xform.software

  # if there is report file generated during the transformation processing, record the 
  # parsed errors in the event detail
  rescue RecordConversionError => oe
    @event_outcome = 'failure'
    @errors = xform.errors
  rescue InstructionError => ie
    Datyl::Logger.err "#{ie.message}"
    halt 501, "#{ie.message}"
  rescue TransformationError => te
    Datyl::Logger.err "#{te.message}\n#{te.backtrace.join('\n')}"
    halt 500, "#{te.message}\n#{te.backtrace.join('\n')}"
  rescue => e
    Datyl::Logger.err "exception: #{e.message}\n#{e.backtrace.join('\n')}"
    halt [500, "exception: #{e.message}\n#{e.backtrace.join('\n')}"]
  end

  # remove temp file
  if io
    io.unlink
  end
  # dump the xml output to the response
  headers 'Content-Type' => 'application/xml'
  body erb(:result)
  xform = nil
end

#download the file defined in the [;path] parameter
get '/file' do
  path = params[:path]
  unless path
    Datyl::Logger.err "need to specify the resource"
    halt 400, "need to specify the resource" 
  end

  unless (File.exist?(path) && File.file?(path)) 
    Datyl::Logger.err "#{path} is no longer available"
    halt 410, "#{path} is no longer available"
  end

  # build the response and send the file back
  status 200
  headers "Content-Type" => "application/octet-stream", "Content-Length" => File.size(path).to_s
  send_file path

  # delete the file after a successful GET
  File.delete(path)
  Datyl::Logger.info "#{path} has been retrieved and deleted"
  # delete the parent directory if it's empty
  if (Dir.entries(File.dirname(path)) == [".", ".."])
    Dir.delete(File.dirname(path))
  end
end

# define the file in the [:path] parameter, typically after the file has been retrieved through the get method
delete '/file' do
  # get params from request
  path = params[:path]
  unless path
    Datyl::Logger.err "need to specify the resource  to the requested file" 
    halt 400, "need to specify the resource  to the requested file" 
  end
  
  if (File.exist?(path) && File.file?(path)) then
    File.delete(path)
  else
    Datyl::Logger.err "#{path} is no longer available"
    halt 410, "#{path} is no longer available"
  end

end

# POST a file to the transformation service to convert the file based on the transformID
# ex:  curl -F file=@GLASS.WAV http://localhost:7006/transform/wave_norm
post '/transform/:id' do |transformID|
   begin
    halt 400, "missing parameter file='@filename'" unless params['file']
    halt 400, "missing [file][:tempfile] parameter file='@filename'" unless params['file'][:tempfile]

    sourcepath =  params['file'][:tempfile].path
 
    xform = XformModule.new($tempdir, config)
    xform.retrieve(transformID)

    @event_outcome = "success"
    @result = xform.transform(sourcepath) 
    @agentId =  xform.identifier
    @agentNote = xform.software
    xform = nil  
   
    # remove the temporary file created by sinatra-curl
    params['file'][:tempfile].unlink unless params['file'][:tempfile].nil?
    
  # if there is report file generated during the transformation processing, record the 
  # parsed errors in the event detail
  rescue RecordConversionError => oe
    @event_outcome = 'failure'
    @errors = xform.errors
  rescue InstructionError    => ie
    Datyl::Logger.err "#{ie.message}"
    halt 501, "#{ie.message}"
  rescue TransformationError => te
    Datyl::Logger.err "#{te.message}\n#{te.backtrace.join('\n')}"
    halt 500, "#{te.message}\n#{te.backtrace.join('\n')}"
  rescue => e
    Datyl::Logger.err "exception: #{e.message}\n#{e.backtrace.join('\n')}"
    halt [500, "exception: #{e.message}\n#{e.backtrace.join('\n')}"]
  end

  # dump the xml output to the response
  headers 'Content-Type' => 'application/xml'
  body erb(:result) 
end

get '/status' do
  [ 200, {'Content-Type'  => 'application/xml'}, "<status/>\n" ]
end

# clean up the temp directory used by the transformation service upon shutting down the transformation service.
at_exit do
  Datyl::Logger.info "SHUTTING DOWN!, cleaning up #{$tempdir}"
  begin
    FileUtils.remove_entry_secure($tempdir)
  rescue e
    Datyl::Logger.info  "running into exception #{e}, #{e.message}\n#{e.backtrace.join('\n')}"
  end
end
