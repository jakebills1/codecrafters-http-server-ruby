require "socket"

# suppress warning about ractors
Warning[:experimental] = false

class Request
  attr_accessor :verb, :target, :version, :headers, :body
end

server = TCPServer.new("localhost", 4221)

while (client_socket, client_address = server.accept)
  Ractor.new(client_socket) do |socket|
    request = Request.new
    line = socket.readline("\r\n", chomp: true)
    # read request line
    request.verb, request.target, request.version = line.split(' ')
    # puts request.verb, request.target, request.version
    status = if request.target != '/'
               "404 Not Found"
             else
               "200 OK"
             end
    socket.write "#{request.version} #{status}\r\n\r\n"
  end
end

