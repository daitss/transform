require 'xml'

# a class dedicated to parse the report file generated from pdfapilot software
class PdfapilotParser 
  def initialize(report_file)
    @document = open(report_file) { |io| XML::Document.io io }
  end
  
  def parse
    # retrieve the transformation conversion error from the report.
    namespace = "callas:http://www.callassoftware.com/namespace/pi4"
    failures = @doc.find("//callas:fixup[@severity='ERROR']", namespace)
    unless failures.nil?
      # retrieve the detail description of the fixup errors
      failures.each do |failure|
          id = failure.find_first("@fixup_id", namespace).value
          details_node = failure.find_first("callas:details", namespace)
          unless details_node.nil?
            error = @doc.find_first("//callas:fixup[@fixup_id='#{id}']/callas:display_name", namespace).content  
              + details_node.content 
          else
            error =  @doc.find_first("//callas:fixup[@fixup_id='#{id}']/callas:display_name", namespace).content
          end
          errors << error
      end
    end
    errors
  end
end