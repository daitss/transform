require 'xml'

CONFIGFILE = 'config/transform.xml'
INPUTFILE = '#INPUT_FILE#'
OUTPUTFILE = '#OUTPUT_FILE#'
BOUNDARY = '--page'

class xformModule

  def initialize(tempdir)
     @config = XML::Document.file(CONFIGFILE)
     @tempdir = tempdir
  end
  
  def retrieve(transformID)
    # retrieve the designated processing instruction from the config file
    transformID.upcase!
     transformation = config.find_first("/transformations/transformation[@ID='#{transformID}']")

     if (transformation == nil)
       throw Exception.new "cannot find transformation #{transformID}"]
     end

     #retrieve the transformation instruction
     @instruction = transformation.find_first("//instruction/text()")
     if @instruction.nil?
       throw  Exception.new "no transformation instruction is defined for #{transformID}"]
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
    FileUtils.makedirs( @tempdir + filename)
    outputpath =  @tempdir + filename + "/" + "transformed" + @extension
    command = @instruction.sub(INPUTFILE, @sourcepath).sub(OUTPUTFILE, outputpath)

    # Log4r::Logger[LOGGERNAME].info command
    # backquote the external program, do the transformation 
    `#{command}`
    if ($? != 0)
      # clean up
      FileUtils.rmdir( @tempdir + filename)
      throw Exception.new "#{command} failed"
    end

    # build the response
    tmpfiles =  @tempdir + filename + "/*"

    # sorted by the numerical order of the file name,
    # mtime only goes to seconds, so can't do this :(   File.mtime(x) <=> File.mtime(y) 
    files = Dir.glob(tmpfiles).sort { |x,y| x =~ /.*?(\d+).*/; xn = $1.to_i; y =~ /.*?(\d+).*/; yn = $1.to_i; xn <=> yn }     
    
    files
end