require "socket"
require "optionparser"

OPTIONS = {}
OptionParser.new do |parser|
  parser.on("--directory DIRECTORY") do |dir|
    OPTIONS['file_dir'] = dir
  end
end.parse!

OPTIONS.freeze

class Request
  attr_accessor :verb, :target, :version, :headers, :body

  def initialize
    @headers = {}
  end
end
class Response
  VALID_ENCODINGS = ['gzip'].freeze
  attr_accessor :version, :status, :body, :content_type, :content_encoding

  def initialize
    @content_type = 'text/plain'
  end


  def self.from_request(request)
    response = new
    response.version = request.version
    case [request.verb, parse_path(request.target)]
    when %w[GET /]
      response.status = '200 OK'
    when %w[GET /echo]
      request_encoding = request.headers['Accept-Encoding']
      if VALID_ENCODINGS.include? request_encoding
        response.content_encoding = request_encoding
      end
      response.body = request.target.split('/').last
      response.status = '200 OK'
    when %w[GET /user-agent]
      response.body = request.headers['User-Agent']
      response.status = '200 OK'
    when %w[GET /files]
      file_path = OPTIONS['file_dir'] + request.target.split('/').last
      if File.exist?(file_path)
        file = File.read(file_path)
        response.content_type = 'application/octet-stream'
        response.body = file
        response.status = '200 OK'
      else
        response.status = '404 Not Found'
      end
    when %w[POST /files]
      file_path = OPTIONS['file_dir'] + request.target.split('/').last
      File.write(file_path, request.body)
      response.status = '201 Created'
    else
      response.status = '404 Not Found'
    end
    response
  end

  def write_headers
    headers = ''
    headers += "Content-Type: #{content_type}\r\n" if content_type
    headers += "Content-Length: #{body.bytesize}\r\n" if body
    headers += "Content-Encoding: #{content_encoding}\r\n" if content_encoding
    headers
  end

  def write_body
    return '' unless body

    body
  end

  def write_request_line
    "#{version} #{status}"
  end

  def to_s
    "#{write_request_line}\r\n#{write_headers}\r\n#{write_body}"
  end

  # returns first path segment for matching purposes
  def self.parse_path(path)
    idx_of_second_path_segment = path.index('/', 1)
    return path unless idx_of_second_path_segment

    path[0, idx_of_second_path_segment]
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
    # read body
    if (body_bytes = request.headers.dig('Content-Length'))
      request.body = socket.read(body_bytes.to_i)
    end
    # puts request.verb, request.target, request.version
    socket.write Response.from_request(request)
  end
end

