module Logging

  def log_error(message, exception = nil)
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    File.open('error.log', 'a') do |file|
      file.puts("[#{timestamp}] ERROR: #{message}")
      file.puts("[#{timestamp}] BACKTRACE: #{exception.backtrace.join("\n")}") if exception
    end
  end

  def handle_error(message, exception = nil)
    log_error(message, exception)
    puts "\n"
    puts message
    puts exception.backtrace if exception
  end
end
