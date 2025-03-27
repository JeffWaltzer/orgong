require_relative 'logging'

class PromptFetcher
  def self.fetch(file_path)
    return unless file_path && File.exist?(file_path)
    escaped_file_path = Shellwords.escape(file_path)
    json = `~/bin/exiftool/exiftool -s3 -u -Generation_data #{escaped_file_path} 2>&1`
    return nil if json.empty?
    begin
      JSON.parse(json)['prompt']
    rescue JSON::ParserError => e
      handle_error(e.message, e)
    end
  end
end