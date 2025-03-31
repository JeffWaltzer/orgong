require_relative 'logging.rb'
require 'curses'

class CommandLineApp

  include Logging

  def initialize(directory, search_string, label, list_mode = false, recursive = false, minimum: 0)
    @minimum = minimum
    @directory = File.expand_path(directory)
    @search_string = search_string
    @label = label
    @list_mode = list_mode
    @recursive = recursive
    setup_processed_folder
  end

  def update_window(message)
    @bottom_window.addstr(message)
    @bottom_window.refresh
  end

  def setup_processed_folder
    @processed_folder = File.join(@directory, @label || '')
    create_directory(@processed_folder)
  end

  def create_directory(directory)
    Dir.mkdir(directory) unless Dir.exist?(directory)
  rescue SystemCallError => e
    handle_error("Error creating directory '#{directory}': #{e.message}", e)
    exit(1)
  end

  def run
    validate_directory
    Curses.init_screen
    begin
      setup_curses_windows
      @list_mode ? list_files : process_files
    ensure
      Curses.close_screen
    end
  end

  private

  def setup_curses_windows
    @top_window = Curses::Window.new(11, Curses.cols, 0, 0)

    @bottom_window = Curses::Window.new(Curses.lines - 11, Curses.cols, 11, 0)
    @bottom_window.scrollok(true)
  end

  def validate_directory
    validate_path(@directory)
  end

  def validate_path(path)
    DirectoryValidator.validate!(path)
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
      puts "File: #{file_path} -> #{PromptFetcher.fetch(file_path)}.inspect"
    end
  end

  def filter_files
    files = if @recursive
              Dir.glob(File.join(@directory, '**', '*'), File::FNM_DOTMATCH)
            else
              Dir.children(@directory).map { |file| File.join(@directory, file) }
            end
    files.select { |file_path| valid_file?(file_path) }
  end

  def valid_file?(file_path)
    File.file?(file_path) && !File.basename(file_path).start_with?('.')
  end

  def process_files
    @bottom_window ||= Curses::Window.new(Curses.lines - 11, Curses.cols, 11, 0)
    @bottom_window.scrollok(true)

    update_window("Processing files in '#{@directory}'...\n")
    filter_files.each_with_index do |file_path, index|
      @top_window.addstr("\ncount: #{index + 1}")
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
    top_words = calculate_top_words(@freq, 8)
    refresh_top_window(top_words) if top_words != @previous_top_words
    @previous_top_words = top_words
  end

  def calculate_top_words(frequencies, limit)
    frequencies.sort_by { |_, count| -count }.first(limit)
  end

  def refresh_top_window(top_words)
    @top_window.clear
    @top_window.setpos(0, 0)
    @top_window.addstr("-------#{@search_string} => #{@label} #{@directory}\n")
    top_words.each { |word, count| @top_window.addstr("'#{word}' with count: #{count}\n") }
    @top_window.addstr("------ #{@freq.size}")
    @top_window.refresh
  end


  def valid_prompt?(prompt)
    prompt && (@search_string.nil? || prompt.include?(@search_string))
  end

  def process_file(file_path, minimum)
    prompt = PromptFetcher.fetch(file_path)

    countwords(prompt, minimum)
    return unless valid_prompt?(prompt)

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
      update_window("Moved '#{file_path}' to '#{@processed_folder}'.\n")
    rescue SystemCallError => e
      msg = "Error moving file '#{file_path}' to '#{@processed_folder}': #{e.message}"
      handle_error(msg, e)
      update_window("#{msg}\n")
    end

  end
end
