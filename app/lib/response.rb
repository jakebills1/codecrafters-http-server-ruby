# frozen_string_literal: true

class Response
  VALID_ENCODINGS = ['gzip'].freeze
  attr_accessor :version, :status, :body, :content_type, :content_encoding

  def initialize
    @content_type = 'text/plain'
  end


  def self.from_request(request, options)
    response = new
    response.version = request.version
    case [request.verb, parse_path(request.target)]
    when %w[GET /]
      response.status = '200 OK'
    when %w[GET /echo]
      request_encodings = request.headers['Accept-Encoding']&.split(', ') || []
      valid_encodings = VALID_ENCODINGS & request_encodings
      unless valid_encodings.empty?
        response.content_encoding = valid_encodings.first
      end
      response.body = if response.content_encoding && response.content_encoding == 'gzip'
                        Zlib.gzip request.target.split('/').last
                      else
                        request.target.split('/').last
                      end
      response.status = '200 OK'
    when %w[GET /user-agent]
      response.body = request.headers['User-Agent']
      response.status = '200 OK'
    when %w[GET /files]
      file_path = options['file_dir'] + request.target.split('/').last
      if File.exist?(file_path)
        file = File.read(file_path)
        response.content_type = 'application/octet-stream'
        response.body = file
        response.status = '200 OK'
      else
        response.status = '404 Not Found'
      end
    when %w[POST /files]
      file_path = options['file_dir'] + request.target.split('/').last
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

  def to_s(with_body: true)
    "#{write_request_line}\r\n#{write_headers}\r\n#{with_body ? write_body : ''}"
  end

  # returns first path segment for matching purposes
  def self.parse_path(path)
    idx_of_second_path_segment = path.index('/', 1)
    return path unless idx_of_second_path_segment

    path[0, idx_of_second_path_segment]
  end
end
