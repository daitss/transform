require "rubygems"

class MsgPart
  attr_accessor :filename, :content
  def initialize(filename, content )
    @filename = filename
    @content = content
  end

  def to_multipart
    return "Content-Transfer-Encoding: binary\r\n" + "Content-Type: aplication/octet-stream\r\n\r\n" + @content + "\r\n"
  end
end