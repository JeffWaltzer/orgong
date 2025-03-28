require 'optparse'
require 'ostruct'

class OptionsHandler
  def self.parse(args)
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

      opts.on("--minimum MINIMUM",
              "Minimal word length for freq") do |minimum|
        options.minimum = minimum.to_i
      end

      opts.on("--list", "List the matching prompts without moving files.") do
        options.list = true
      end

      opts.on("--recursive", "Process directories recursively.") do
        options.recursive = true
      end
    end

    begin
      option_parser.parse!(args)
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
      puts "Option Parsing Error: #{e.message}"
      puts option_parser
      exit(1)
    end

    validate_arguments(options, args, option_parser)

    { options: options, directory: File.expand_path(args.first) }
  end

  def self.validate_arguments(options, args, option_parser)
    if (!options.list && !(options.label ||= options.search.match?(/\A[a-zA-Z]+\z/) ? options.search : nil) && options.search) || (options.list && args.size != 1)
      puts "\nError: '--label' and '--search' arguments are required unless '--list' is specified with a directory."
      puts option_parser
      exit(1)
    end

    if args.empty? || args.size > 1
      puts "Option Parsing Error: Specify exactly one directory."
      exit(1)
    end
  end
end