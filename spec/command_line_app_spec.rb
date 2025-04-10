require_relative '../lib/command_line_app'
require_relative '../lib/prompt_fetcher'
require_relative '../lib/directory_validator'


RSpec.describe CommandLineApp do
  let(:directory) { '/tmp' }
  let(:search_string) { 'search_keyword' }
  let(:label) { 'processed' }
  let(:list_mode) { false }
  let(:recursive) { false }
  let(:app) { described_class.new(directory, search_string, label, list_mode, recursive) }
  let(:processed_folder) { File.join(directory, label) }

  before do
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:mkdir).and_call_original
    allow(FileUtils).to receive(:mv)
    allow(PromptFetcher).to receive(:fetch).and_return(nil)
    allow(DirectoryValidator).to receive(:validate!)
  end

  describe '#initialize' do

    context 'when list_mode is true' do
      let(:list_mode) { true }

      it 'does not create the processed folder' do
        expect(Dir).not_to receive(:mkdir)
        app
      end
    end
  end

  describe '#run' do
    context 'when in list mode' do
      let(:list_mode) { true }

      it 'calls list_files' do
        expect(app).to receive(:list_files)
        app.run
      end
    end

    context 'when not in list mode' do
      it 'calls process_files' do
        expect(app).to receive(:process_files)
        app.run
      end
    end
  end

  describe '#setup_processed_folder' do

    context 'when the processed folder already exists' do
      it 'does not create the folder' do
        allow(Dir).to receive(:exist?).with(processed_folder).and_return(true)
        expect(Dir).not_to receive(:mkdir)
        app.send(:setup_processed_folder)
      end
    end
  end

  describe '#list_files' do
    it 'lists files with matching prompts' do
      allow(app).to receive(:filter_files).and_return(['/test_directory/test_file.txt'])
      allow(PromptFetcher).to receive(:fetch).with('/test_directory/test_file.txt').and_return('matching_prompt')

      expect {
        app.send(:list_files)
      }.to output(/Listing files with relevant prompts/).to_stdout

      expect {
        app.send(:list_files)
      }.to output(/File: test_file.txt\nPrompt:\nmatching_prompt\n\n/).to_stdout
    end
  end

  describe '#process_files' do
    it 'processes and moves files with matching prompts and search_string' do
      allow(app).to receive(:filter_files).and_return(['/test_directory/test_file.txt'])
      allow(PromptFetcher).to receive(:fetch).with('/test_directory/test_file.txt').and_return('matching_prompt_with_search_keyword')

      expect(app).to receive(:move_file).with('/test_directory/test_file.txt')

      expect {
        app.send(:process_files)
      }.to output(/Processing files in the directory '#{directory}' search #{search_string} to #{label}/).to_stdout
    end
  end

  describe '#process_file' do
    it 'moves files with matching prompts' do
      allow(PromptFetcher).to receive(:fetch).with('/test_directory/test_file.txt').and_return('matching_search_keyword')

      expect(app).to receive(:move_file).with('/test_directory/test_file.txt')
      expect {
        app.send(:process_file, '/test_directory/test_file.txt')
      }.to output(/test_file.txt:\nmatching_search_keyword\n\n/).to_stdout
    end

    it 'skips files without matching prompts' do
      allow(PromptFetcher).to receive(:fetch).with('/test_directory/test_file.txt').and_return('non_matching_prompt')

      expect(app).not_to receive(:move_file)
      app.send(:process_file, '/test_directory/test_file.txt')
    end
  end

end