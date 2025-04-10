class DirectoryValidator
  def self.validate!(directory)
    unless Dir.exist?(directory)
      puts "\n"
      puts "The directory '#{directory}' does not exist."
      raise 'Invalid directory.'
    end
  end
end
