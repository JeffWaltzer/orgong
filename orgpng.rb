#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'

# Define a class for the program logic
class CommandLineApp
  def initialize(directory, search_string, label)
    @directory = File.expand_path(directory)
    @search_string = search_string
    @label = label

    def run
      if !Dir.exist?(@directory)
        puts "The directory '#{@directory}' does not exist."
        exit(1)
      end

      puts "Processing files in the directory '#{@directory}':"

      # Iterate over files in the directory
      Dir.foreach(@directory) do |file|
        file_path = File.join(@directory, file)

        # Skip directories and hidden files (like `.`, `..`)
        next if File.directory?(file_path)

        # Process the file (for now, just output its name)
        next unless @search_string.nil? || file.include?(@search_string)

        # exiftool -s3 -u -Generation_data  /mnt/chromeos/SMB/file.png | jq '.prompt'

        json = ` ~/bin/exiftool/exiftool  -s3 -u -Generation_data  #{file_path} 2>&1 `

        next if json.empty?

        begin
          puts "#{file}  #{@label.inspect} #{JSON.parse(json)['prompt']}"
        rescue JSON::ParserError => e
          puts "JSON Parsing Error: #{e.message}"
          puts "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
          puts "parsing: #{json.inspect}"
          nil # Return nil or handle it according to your logic
        end

      end
    end
  end
end

# Parse command-line arguments
options = OpenStruct.new

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: script_name.rb directory --search SEARCH_STRING --label LABEL"

  opts.on("--search SEARCH_STRING", "The search string to filter files (required).") do |search|
    options.search = search
  end

  opts.on("--label LABEL", "The label to append to output.") do |label|
    options.label = label
  end
end

if options.label.nil? || options.search.nil?
  puts "Error: Both '--label' and '--search' arguments are required."
  puts option_parser
  exit(1)
end

begin
  option_parser.parse!
rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
  puts e.message
  puts option_parser
  exit(1)
end

if ARGV.empty?
  puts "Error: A directory name is required."
  puts option_parser
  exit(1)
end

directory = ARGV.first

# Main execution

app = CommandLineApp.new(directory, options.search, options.label)
app.run
