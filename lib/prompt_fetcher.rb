require_relative 'logging'

class PromptFetcher
  extend Logging
  def self.fetch(file_path)
    return unless file_path && File.exist?(file_path)
    escaped_file_path = Shellwords.escape(file_path)
    json = `~/bin/exiftool/exiftool -s3 -u -Generation_data #{escaped_file_path} 2>&1`
    begin
      JSON.parse(json)['prompt'] if json && json[0]=='{'
    rescue JSON::ParserError => e
      handle_error(e.message, e)
    end
  end
end