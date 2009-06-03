#!/usr/bin/ruby
require 'mongrel'
require 'cgi'
require 'rubygems'
require 'log4r'

class FileHandler < Mongrel::HttpHandler
  def initialize
    
  end

  def process(request, response)
    if request.params["HTTP_VERSION"] != "HTTP/1.1"
      response.start(505) { |header, body| 
        body.write("ERROR: unsupported HTTP version #{request.params["HTTP_VERSION"]}")}
      else
        begin
          method = request.params["REQUEST_METHOD"]

          case method
          when 'GET'
            get(request, response)
          when 'DELETE'
            delete(request, response)
          else
            response.start(405) do |header, body|
              header["Allow"] = "GET, DELETE"
            end
          end

        rescue HTTPError => ex
          if (ex.status_code < 500)
            Log4r::Logger[LOGGERNAME].warn "HTTP #{ex.status_code} #{ex.status_message}"
          else
            Log4r::Logger[LOGGERNAME].error "HTTP #{ex.status_code} #{ex.status_message}"
          end

          response.start(ex.status_code) { |header, body| body.write(ex.status_message)}
        end
      end
    end
  end

  def get(request, response)    
    # get params from request
    path = request.params["PATH_INFO"]
    
    unless path.nil?
      Log4r::Logger[LOGGERNAME].info "path = #{path}"
      if (File.exist?(path) && File.file?(path)) then
        # build the response
        response.start(200) do |header, body|
          header["Content-Type"] = "application/octet-stream"
          header["Content-Length"] = File.size(path)
          fhandle = File.open(path)

          body.write(fhandle.read)
          body.flush
        end
        #delete the file after successful GET
        File.delete(path)
        puts "#{path} has been retrieved and deleted"
        #delete the parent directory if it's empty
        if (Dir.entries(File.dirname(path)) == [".", ".."])
          Dir.delete(File.dirname(path))
        end
        
      else
        raise HTTPError.new(410, '#{path} is no longer available')
      end
    else
      raise HTTPError.new(400, "need to specify the resource")
    end
  end

  def delete(request, response)
    # get params from request
    path = request.params["PATH_INFO"]

    unless path.nil?
      Log4r::Logger[LOGGERNAME].info "path = #{path}"
      if (File.exist?(path) && File.file?(path)) then
        File.delete(path)
        Log4r::Logger[LOGGERNAME].info "#{path} is deleted successfully."
        
        # build the response
        response.start(204) { |header, body| }
      else
        raise HTTPError.new(410, "#{path} is no longer available")
      end
    else
      raise HTTPError.new(400, "need to specify the resource to the requested file")
    end
  end
