#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'

# Define a class for the program logic

class CommandLineApp
  def initialize(directory, search_string, label, list_mode = false)

    @directory = File.expand_path(directory)
    @search_string = search_string
    @label = label
    @list_mode = list_mode
    @processed_folder = list_mode ? nil : File.join(@directory, @label)
    Dir.mkdir(@processed_folder) if @processed_folder && !Dir.exist?(@processed_folder)
  end

  def run
    validate_directory
    @list_mode ? list_files : process_files
  end

  private

  def validate_directory
    return if Dir.exist?(@directory)
    puts "The directory '#{@directory}' does not exist."
    exit(1)
  end

  def fetch_prompt(file_path)
    require 'shellwords'
    return unless file_path && File.exist?(file_path)
    escaped_file_path = Shellwords.escape(file_path)
    json = `~/bin/exiftool/exiftool -s3 -u -Generation_data #{escaped_file_path} 2>&1`
    return if json.empty?
    begin
      JSON.parse(json)['prompt']
    rescue JSON::ParserError => e
      puts "Error parsing JSON for file '#{file_path}': #{e.message}"
      puts e.backtrace
      nil

      puts e.backtrace
      nil
    end
  end

  def list_files
    puts "Listing files with relevant prompts in directory '#{@directory}':"
    Dir.children(@directory).each do |file|
      file_path = File.join(@directory, file)
      next if File.directory?(file_path) || file.start_with?('.')
      prompt = fetch_prompt(file_path)
      puts "File: #{file}\nPrompt:\n#{prompt}\n\n" if prompt
    end
  end

  def process_files
    puts "Processing files in the directory '#{@directory}' search #{@search_string} to #{@label}"
    Dir.children(@directory).each do |file|
      file_path = File.join(@directory, file)
      next if File.directory?(file_path)
      prompt = fetch_prompt(file_path)
      next unless prompt && (@search_string.nil? || prompt.include?(@search_string))
      puts "#{file}:\n#{prompt}\n\n"
      File.rename(file_path, File.join(@processed_folder, file)) if @processed_folder
    end
  end
end

# Parse command-line arguments
options = OpenStruct.new

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: script_name.rb directory --search SEARCH_STRING --label LABEL"

  opts.on("--search SEARCH_STRING",
          "The search string to filter files (required).") do |search|
    options.search = search
  end

  opts.on("--label LABEL",
          "The label to append to output.") do |label|
    options.label = label
  end

  opts.on("--list", "List the matching prompts without moving files.") do
    options.list = true
  end
end

begin
  option_parser.parse!
rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
  puts e.message
  puts e.backtrace
  puts option_parser
  exit(1)
end

puts "Options: #{options.to_h.inspect} ARGV: #{ARGV.inspect}"

if (!options.list && (options.label.nil? || options.search.nil?)) || (options.list && ARGV.size != 1)

  if options.list && !options.search.nil?
    puts "Error: '--search' argument cannot be used with '--list' as it implies processing of files."
    puts option_parser
    exit(1)
  end

  puts "Error: '--label' and '--search' arguments are required unless '--list' is specified with a directory."
  puts option_parser
  exit(1)
end

if ARGV.empty?
  puts "Error: A directory name is required when '--list' is specified."
  puts option_parser
  exit(1)
end

directory = File.expand_path(ARGV.first)
list_mode = options.list

# Main execution
app = CommandLineApp.new(directory, options.search, options.label, list_mode)
app.run
