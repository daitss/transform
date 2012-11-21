require 'xml'


INPUTFILE = '$INPUT_FILE$'
OUTPUTFILE = '$OUTPUT_FILE$'
BOUNDARY = '--page'
IDPREFIX = "info:fda/daitss/transform/"

class InstructionError < StandardError; end
class TransformationError < StandardError; end

class XformModule
   attr_reader :software
   attr_reader :identifier
      
  def initialize(tempdir, config)
    @config = config
    @tempdir = tempdir
  end

  def finalize
  end
  
  def retrieve(transformID)
    # retrieve the designated processing instruction from the config file
    transformID.downcase!
    transformation = @config.send(transformID)

    if (transformation == nil)
      raise InstructionError.new("cannot find transformation #{transformID}")
    end

    # retrieve the transformation instruction
    @instruction = transformation["instruction"]
    if @instruction.nil?
      raise InstructionError.new("no transformation instruction is defined for #{transformID}")
    end

    # retrieve the file extension to be used for the output file, to ensure the outputfile will be identified correctly
    @extension = transformation["extension"]
    @extension = ""  if @extension.nil?

    # retrieve the agent identifier for the software used in the transformation
    @identifier =  transformation["identifier"]
    if @identifier.nil?
      @identifier = IDPREFIX 
    else
      @identifier = IDPREFIX +  @identifier.to_s
    end
    
    # retrieve detail software information used by the transformation
    @software =  transformation["software"]
    @software = ""  if @software.nil?
  
  end

  # XXX host_url is not used with relativepaths, if we continue to go this way we can take it out.
  def transform(sourcepath)
    # extract the file name port from the source path
    ext = File.extname(sourcepath)
    filename = File.basename(sourcepath, ext)
    # create a directory to hold the transformed files
    FileUtils.makedirs( @tempdir + "/" + filename)
    outputpath =  @tempdir  + "/" + filename + "/" + "transformed" + @extension
    command = @instruction.sub(INPUTFILE, sourcepath).sub(OUTPUTFILE, outputpath)

    # backquote the external program, do the transformation 
    `#{command}`
    if ($? != 0)
      # clean up
      FileUtils.rmdir( @tempdir  + "/" + filename)
      raise TransformationError.new("#{command} failed")
    end

    # build the response
    tmpfiles =  @tempdir  + "/" + filename + "/*"

    # sorted by the numerical order of the file name,
    # mtime only goes to seconds, so can't do this :(   File.mtime(x) <=> File.mtime(y) 
    files = Dir.glob(tmpfiles).sort { |x,y| x =~ /.*?(\d+).*/; xn = $1.to_i; y =~ /.*?(\d+).*/; yn = $1.to_i; xn <=> yn }     
  end
end
