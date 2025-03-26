#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'
require 'shellwords'
require 'fileutils'

# Define a class for the program logic

class DirectoryValidator
  def self.validate!(directory)
    unless Dir.exist?(directory)
      puts "\n"
      puts "The directory '#{directory}' does not exist."
      exit(1)
    end
  end
end

class PromptFetcher
  def self.fetch(file_path)

    return unless file_path && File.exist?(file_path)
    escaped_file_path = Shellwords.escape(file_path)
    json = `~/bin/exiftool/exiftool -s3 -u -Generation_data #{escaped_file_path} 2>&1`
    return nil if json.empty?
    begin
      JSON.parse(json)['prompt']
    rescue JSON::ParserError => e
      puts "\n"
      puts "Error parsing JSON for file '#{file_path}': #{e.message}"
      puts e.backtrace
      nil
    end
  end
end

class CommandLineApp

  def initialize(directory, search_string, label, list_mode = false, recursive = false)
    @directory = File.expand_path(directory)
    @search_string = search_string
    @label = label
    @list_mode = list_mode
    @recursive = recursive
    setup_processed_folder unless list_mode
    @directory = File.expand_path(directory)
    @search_string = search_string
    @label = label
    @list_mode = list_mode
    setup_processed_folder unless list_mode
  end

  def setup_processed_folder
    @processed_folder = File.join(@directory, @label)
    begin
      Dir.mkdir(@processed_folder) unless Dir.exist?(@processed_folder)
    rescue SystemCallError => e
      puts "\n"
      puts "Error creating directory '#{@processed_folder}': #{e.message}"
      puts e.backtrace
      exit(1)
    end
  end

  def run
    validate_directory
    @list_mode ? list_files : process_files
  end

  private

  def validate_directory
    DirectoryValidator.validate!(@directory)
  end

  def handle_error(message, exception = nil)
    puts "\n"
    puts message
    puts exception.backtrace if exception
    exit(1)
  end

  def validate_options(options, args, parser)
    if (!options.list && !(options.label && options.search)) || options.list && args.size != 1
      if options.list && options.search
        handle_error("'--search' is incompatible with '--list'.", nil)
      end
      handle_error("'--label' and '--search' arguments are required unless '--list' is specified with a directory.", nil)
    end
  end

  def validate_directory_argument(args, parser)
    handle_error("Specify exactly one directory.", nil) if args.empty? || args.size > 1
  end

  def fetch_prompt(file_path)

    return unless file_path && File.exist?(file_path)
    escaped_file_path = Shellwords.escape(file_path)
    PromptFetcher.fetch(file_path)

  end

  def list_files
    puts "Listing files with relevant prompts in directory '#{@directory}':"
    filter_files.each do |file_path|
      display_file_prompt(file_path)
    end
  end

  def filter_files
    files = if @recursive
              Dir.glob(File.join(@directory, '**', '*'), File::FNM_DOTMATCH)
            else
              Dir.children(@directory).map { |file| File.join(@directory, file) }
            end
    files.select { |file_path| File.file?(file_path) && !File.basename(file_path).start_with?('.') }
         .select { |file_path| File.file?(file_path) && !File.basename(file_path).start_with?('.') }
  end

  def display_file_prompt(file_path)
    prompt = PromptFetcher.fetch(file_path)
    return unless prompt
    puts "File: #{File.basename(file_path)}\nPrompt:\n#{prompt}\n\n"
  end

  def process_files
    puts "Processing files in the directory '#{@directory}' search #{@search_string} to #{@label}"
    filter_files.each do |file_path|
      process_file(file_path)
    end
  end

  def process_file(file_path)
    prompt = PromptFetcher.fetch(file_path)
    return unless prompt && (@search_string.nil? || prompt.include?(@search_string))
    puts "\n"
    puts "#{File.basename(file_path)}:\n#{prompt}\n\n"
    move_file(file_path)
  end

  def move_file(file_path)
    return unless @processed_folder
    begin
      FileUtils.mv(file_path, File.join(@processed_folder, File.basename(file_path)))
    rescue SystemCallError => e
      handle_error("Error moving file '#{file_path}' to '#{@processed_folder}': #{e.message}", e)
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

  opts.on("--recursive", "Process directories recursively.") do
    options.recursive = true
  end
end

begin
  option_parser.parse!
rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
  puts "\n"
  puts "Option Parsing Error: #{e.message}"
  puts e.backtrace
  puts option_parser
  exit(1)
end

puts "Options: #{options.inspect}, ARGV: #{ARGV.inspect}"

if (!options.list && !(options.label && options.search)) || options.list && ARGV.size != 1

  if options.list && options.search
    puts "\n"
    puts "Error: '--search' is incompatible with '--list'."
    puts option_parser
    exit(1)
  end

  puts "\n"
  puts "Error: '--label' and '--search' arguments are required unless '--list' is specified with a directory."
  puts option_parser
  exit(1)
end

if ARGV.empty? || ARGV.size > 1
  puts "\n"
  puts "Error: Specify exactly one directory."

  puts "\n"
  puts "Option Parsing Error: Specify exactly one directory."
  puts caller
  exit(1)
end

directory = File.expand_path(ARGV.first)
list_mode = options.list

# Main execution
app = CommandLineApp.new(directory, options.search, options.label, list_mode, options.recursive)
app.run
