require 'xml'

# This is the list of return code from pdfapilot that we want to report and move-on (i.e. not snafu)
# based on the pdfapilot manual, the return code for encrypted file is 105, but the testing
# revealed that it is 26880 instead.
Report_Error = [26880] 

# a class dedicated to parse the report file generated from pdfapilot software
class PdfapilotParser
  attr_reader :errors 
  def initialize
    @errors = Array.new
  end
  
  def parse_output(output_code, command_output)
    # check if the output_cdoe is in the list of pdfapilot error code to be reported
    if (Report_Error.include?(output_code))
      #record the conversion error message
      @errors << command_output 
    end
    @errors
  end
      
  def parse_xml(report_file)
    doc = open(report_file) { |io| XML::Document.io io }

    # retrieve the transformation conversion error from the report.
    namespace = "callas:http://www.callassoftware.com/namespace/pi4"
    failures = doc.find("//callas:fixup[@severity='ERROR']", namespace)
    unless failures.nil?
      # retrieve the detail description of the fixup errors
      failures.each do |failure|
          id = failure.find_first("@fixup_id", namespace).value
          details_node = failure.find_first("callas:details", namespace)
          unless details_node.nil?
            error = doc.find_first("//callas:fixup[@fixup_id='#{id}']/callas:display_name", namespace).content + 
            ':' + details_node.content.strip 
          else
            error =  doc.find_first("//callas:fixup[@fixup_id='#{id}']/callas:display_name", namespace).content
          end
          @errors << error
      end
    end
    doc = nil
  end
  @errors
end