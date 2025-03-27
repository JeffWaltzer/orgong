require 'fileutils'

class DirectoryManager
  attr_reader :directory

  def initialize(directory)
    @directory = File.expand_path(directory)
  end

  def validate!
    raise ArgumentError, "Invalid directory: #{@directory}" unless Dir.exist?(@directory)
  end

  def list_files(recursive: false, filter: nil)
    # Use Dir.glob for recursive and non-recursive file listing
    files = if recursive
              Dir.glob("#{directory}/**/*")
            else
              Dir.entries(directory).map { |entry| File.join(directory, entry) }
            end

    # Filter files if necessary
    return files unless filter

    files.select { |file| File.file?(file) && File.basename(file).include?(filter) }
  end

  def create_directory(path)
    # Use FileUtils.mkdir_p to safely create directories, including parents
    FileUtils.mkdir_p(path) unless Dir.exist?(path)
  rescue SystemCallError => e
    raise "Error creating directory '#{path}': #{e.message}"
  end

  def move_file(file_path, destination_folder)
    destination_path = File.join(destination_folder, File.basename(file_path))

    # Skip if source and destination are the same
    if File.expand_path(file_path) == File.expand_path(destination_path)
      raise "Move skipped: Source and destination are the same for '#{file_path}'."
    end

    # Move the file
    FileUtils.mv(file_path, destination_path)
  rescue SystemCallError => e
    raise "Error moving file '#{file_path}' to '#{destination_folder}': #{e.message}"
  end
end