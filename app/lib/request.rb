# frozen_string_literal: true

class Request
  attr_accessor :verb, :target, :version, :headers, :body

  def initialize
    @headers = {}
  end
end
