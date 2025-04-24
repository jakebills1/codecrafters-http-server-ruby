# frozen_string_literal: true
require 'optionparser'

class Options
  def self.parse!
    options = {}
    OptionParser.new do |parser|
      parser.on("--directory DIRECTORY") do |dir|
        options['file_dir'] = dir
      end
    end.parse!
    options
  end
end
