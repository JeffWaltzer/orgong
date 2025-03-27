#!/usr/bin/env ruby

require 'json'
require 'shellwords'
require 'fileutils'
require_relative 'lib/directory_validator'
require_relative 'lib/prompt_fetcher'
require_relative 'lib/command_line_app'
require_relative 'lib/options_handler'

# Parse command-line arguments using OptionsHandler
parsed_data = OptionsHandler.parse(ARGV)
options = parsed_data[:options]
directory = parsed_data[:directory]

# Main execution
app = CommandLineApp.new(
  directory,
  options.search,
  options.label,
  options.list,
  options.recursive
)
app.run