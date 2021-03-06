require 'xml'
require 'pdfapilotParser'

INPUTFILE = '$INPUT_FILE$'
OUTPUTFILE = '$OUTPUT_FILE$'
REPORTFILE = '$REPORT_FILE$'
IDPREFIX = "info:fda/daitss/transform/"

class InstructionError < StandardError; end
class TransformationError < StandardError; end
class RecordConversionError < StandardError; end

class XformModule
   attr_reader :software
   attr_reader :identifier
   attr_reader :instruction
   attr_reader :errors
       
  def initialize(tempdir, config)
    @config = config
    @tempdir = tempdir
  end

  # retrieve the processing instruction for the given transformID, as defined in the config file
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
    
    # retrieve the report file that will be used the format transformation tool
    @report_file =  transformation["report_file"]
  end

  # convert the [sourcepath] into a new file with a different file format, based on the extracted instruction.
  def transform(sourcepath)
    @errors = nil
    
    # extract the file name portion from the source path
    ext = File.extname(sourcepath)
    filename = File.basename(sourcepath, ext)
    # create a directory to hold the transformed files
    FileUtils.makedirs( @tempdir + "/" + filename)
    outputpath =  @tempdir  + "/" + filename + "/" + "transformed" + @extension
    report_path = nil
    #if there is a report file that should be generated from the transformation service, add that in the command 
    if @report_file.nil?
      command = @instruction.sub(INPUTFILE, sourcepath).sub(OUTPUTFILE, outputpath)
    else
       report_path = @tempdir + "/" + @report_file
      command = @instruction.sub(INPUTFILE, sourcepath).sub(OUTPUTFILE, outputpath).sub(REPORTFILE, report_path)
    end
      
    # backquote the external program, do the transformation 
    command_output = `#{command}`
    output_code = $?
    
    # parse the report file if a report file is to be generated
    # TODO: currently, we only have pdfapilot parser.  In the future if another parser is added, we will have to 
    # use ruby reflection.
    if report_path
      parser = PdfapilotParser.new
      if File.exists?(report_path)
        @errors = parser.parse_xml(report_path)
        File.delete(report_path)
        raise RecordConversionError.new("record conversion error during #{command}")
      else
        @errors = parser.parse_output(output_code, command_output)
        unless @errors.empty?
          raise RecordConversionError.new("record conversion error during #{command}")
        end
      end         
    end
   
    # problem encountered during format transformation
    if (output_code != 0)      
      # clean up
      if (File.exist?(@tempdir + '/' + filename))
          FileUtils.remove_entry_secure( @tempdir  + '/' + filename)
      end      
      raise TransformationError.new("#{command} failed, output: #{command_output}")
    end
         
    # create the links to output file(s)
    tmpfiles =  @tempdir  + "/" + filename + "/*" + @extension

    # sorted by the numerical order of the file name,
    # mtime only goes to seconds, so can't do this :(   File.mtime(x) <=> File.mtime(y) 
    files = Dir.glob(tmpfiles).sort { |x,y| x =~ /.*?(\d+).*/; xn = $1.to_i; y =~ /.*?(\d+).*/; yn = $1.to_i; xn <=> yn }     
  end
end
