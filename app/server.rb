require "socket"

# suppress warning about ractors
Warning[:experimental] = false

class Request
  attr_accessor :verb, :target, :version, :headers, :body

  def initialize
    @headers = {}
  end
end
class Response
  attr_accessor :version, :status, :body
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
    else
      response.status = '404 Not Found'
    end
    response
  end

  def to_s
    if body
      "#{version} #{status}\r\nContent-Type: text/plain\r\nContent-Length: #{body.size}\r\n\r\n#{body}"
    else
      "#{version} #{status}\r\n\r\n"
    end
  end
end

server = TCPServer.new("localhost", 4221)

while (client_socket, client_address = server.accept)
  Ractor.new(client_socket) do |socket|
    request = Request.new
    line = socket.readline("\r\n", chomp: true)
    # read request line
    request.verb, request.target, request.version = line.split(' ')
    while (line = socket.readline("\r\n", chomp: true)) != ""
      header_key, header_value = line.split(' ')
      request.headers[header_key.delete(':')] = header_value
    end
    # puts request.verb, request.target, request.version
    socket.write Response.from_request(request)
  end
end

