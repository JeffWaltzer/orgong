require_relative 'logging.rb'

class CommandLineApp

  include Logging

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
      handle_error("Error creating directory '#{@processed_folder}': #{e.message}", e)
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
    destination_path = File.join(@processed_folder, File.basename(file_path))
    if File.expand_path(file_path) == File.expand_path(destination_path)
      handle_error("Move skipped: Source and destination paths are the same for '#{file_path}'.")
      return
    end
    begin
      FileUtils.mv(file_path, destination_path)
    rescue SystemCallError => e
      handle_error("Error moving file '#{file_path}' to '#{@processed_folder}': #{e.message}", e)
    end
  end
end
