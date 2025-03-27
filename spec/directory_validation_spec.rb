require_relative '../lib/directory_validator'

RSpec.describe DirectoryValidator do
  describe '.validate!' do
    context 'when the directory exists' do
      it 'does not raise an error' do
        allow(Dir).to receive(:exist?).with('/valid_directory').and_return(true)
        expect { DirectoryValidator.validate!('/valid_directory') }.not_to raise_error
      end
    end

    context 'when the directory does not exist' do
      it 'outputs an error message and exits' do
        allow(Dir).to receive(:exist?).with('/fake_directory').and_return(false)
        expect { DirectoryValidator.validate!('/fake_directory') }.to output(/The directory '\/fake_directory' does not exist/).to_stdout.and raise_error
      end
    end
  end
end