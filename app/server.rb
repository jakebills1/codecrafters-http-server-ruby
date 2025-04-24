require 'socket'
require 'optionparser'
require 'logger'
require 'zlib'
require_relative 'lib/request'
require_relative 'lib/response'
require_relative 'lib/options'

class HTTPServer
  def initialize(options)
    @socket = TCPServer.new("localhost", 4221)
    @options = options || {}
  end

  def serve!
    loop do
      client_socket, _ = socket.accept
      Thread.new(client_socket) do |client|
        request = Request.new
        line = client.readline("\r\n", chomp: true)
        # read request line
        request.verb, request.target, request.version = line.split(' ')
        # read headers
        while (line = client.readline("\r\n", chomp: true)) != ""
          header_key, header_value = line.split(':')
          request.headers[header_key] = header_value.strip
        end
        # read body
        if (body_bytes = request.headers.dig('Content-Length'))
          request.body = client.read(body_bytes.to_i)
        end
        # write response
        response = Response.from_request(request, options)
        client.write response
      end
    end
  end

  private
  attr_reader :socket, :options
end

HTTPServer.new(Options.parse!).serve!