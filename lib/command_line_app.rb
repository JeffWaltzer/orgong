require_relative 'logging.rb'

class CommandLineApp

  include Logging

  def initialize(directory, search_string, label, list_mode = false, recursive = false, minimum: 0)
    @minimum = minimum
    @directory = File.expand_path(directory)
    @search_string = search_string
    @label = label
    @list_mode = list_mode
    @recursive = recursive
    setup_processed_folder unless list_mode
    @directory = File.expand_path(directory)
    @search_string = search_string
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
  end

  def process_files
    filter_files.each do |file_path|
      process_file(file_path, @minimum)
    end
  end

  def countwords(prompt, minimum)
    stop_words = %w[the be to of and a in that have I it for not on with he as you do at this but his by from they we say her she or an will my one all would there their what so up out if about who get which go me when make can like time no just him know take person into year your good some could them see other than then now look only come its over think also back after use two how our work first well way even new want because any these give day most us is are was were]
    @freq ||= Hash.new(0)
    @previous_top_words ||= []
    words = (prompt || '').
      split.reject do |word|
      stop_words.include?(word.downcase) ||
        (minimum && word.length < minimum)
    end
    words.each { |w| @freq[w] += 1 }

    show_top_five

  end

  def show_top_five
    top_five_words = @freq.sort_by { |_, count| -count }.first(5)
    if top_five_words != @previous_top_words
      puts "-------\nTop five most frequent words:"
      top_five_words.each { |word, count| puts "'#{word}' with count: #{count}" }
      @previous_top_words = top_five_words
    end
  end

  def process_file(file_path, minimum)
    prompt = PromptFetcher.fetch(file_path)

    countwords(prompt, minimum)
    return unless prompt &&
      (@search_string.nil? || prompt.include?(@search_string))
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
      puts "Moved '#{file_path}' to '#{@processed_folder}'."
    rescue SystemCallError => e
      handle_error("Error moving file '#{file_path}' to '#{@processed_folder}': #{e.message}", e)
    end
  end
end
