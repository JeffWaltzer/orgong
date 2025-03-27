class DirectoryValidator
  def self.validate!(directory)
    unless Dir.exist?(directory)
      puts "\n"
      puts "The directory '#{directory}' does not exist."
      exit(1)
    end
  end
end
