require "socket"
require "optionparser"

OPTIONS = {}
OptionParser.new do |parser|
  parser.on("--directory DIRECTORY") do |dir|
    OPTIONS['file_dir'] = dir
  end
end.parse!

# @options.freeze

# suppress warning about ractors
Warning[:experimental] = false

class Request
  attr_accessor :verb, :target, :version, :headers, :body

  def initialize
    @headers = {}
  end
end
class Response
  attr_accessor :version, :status, :body, :content_type

  def initialize
    @content_type = 'text/plain'
  end
  def self.from_request(request)
    response = new
    response.version = request.version
    if request.target == '/'
      response.status = '200 OK'
    elsif request.target.start_with?('/echo')
      response.body = request.target.split('/').last
      response.status = '200 OK'
    elsif request.target.start_with?('/user-agent')
      response.body = request.headers['User-Agent']
      response.status = '200 OK'
    elsif request.target.start_with?('/files')
      response.content_type = 'application/octet-stream'
      file_path = OPTIONS['file_dir'] + request.target.split('/').last
      if File.exist?(file_path)
        file = File.read(file_path)
        response.body = file
        response.status = '200 OK'
      else
        response.status = '404 Not Found'
      end
    else
      response.status = '404 Not Found'
    end
    response
  end


  def to_s
    if body
      "#{version} #{status}\r\nContent-Type: #{content_type}\r\nContent-Length: #{body.bytesize}\r\n\r\n#{body}"
    else
      "#{version} #{status}\r\n\r\n"
    end
  end
end

server = TCPServer.new("localhost", 4221)

while (client_socket, client_address = server.accept)
  Thread.new(client_socket) do |socket|
    request = Request.new
    line = socket.readline("\r\n", chomp: true)
    # read request line
    request.verb, request.target, request.version = line.split(' ')
    # read headers
    while (line = socket.readline("\r\n", chomp: true)) != ""
      header_key, header_value = line.split(' ')
      request.headers[header_key.delete(':')] = header_value
    end
    # puts request.verb, request.target, request.version
    socket.write Response.from_request(request)
  end
end

