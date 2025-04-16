require "socket"

# You can use print statements as follows for debugging, they'll be visible when running tests.
print("Logs from your program will appear here!")

# Uncomment this to pass the first stage
#
server = TCPServer.new("localhost", 4221)

while (client_socket, client_address = server.accept)
  Ractor.new(client_socket) do |socket|
    socket.write "HTTP/1.1 200 OK\r\n\r\n"
  end
end
