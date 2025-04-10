require 'spec_helper'
require_relative '../lib/options_handler'

RSpec.describe OptionsHandler do
  describe '.parse' do
    context 'when valid options are provided' do
      it 'parses --search, --label, and directory correctly' do
        args = ['/path/to/directory', '--search', 'keyword', '--label', 'processed']
        result = OptionsHandler.parse(args)

        expect(result[:options].search).to eq('keyword')
        expect(result[:options].label).to eq('processed')
        expect(result[:options].list).to be_nil
        expect(result[:options].recursive).to be_nil
        expect(result[:directory]).to eq(File.expand_path('/path/to/directory'))
      end

      it 'parses --list and directory correctly' do
        args = ['/path/to/directory', '--list']
        result = OptionsHandler.parse(args)

        expect(result[:options].list).to be true
        expect(result[:options].search).to be_nil
        expect(result[:options].label).to be_nil
        expect(result[:options].recursive).to be_nil
        expect(result[:directory]).to eq(File.expand_path('/path/to/directory'))
      end

      it 'parses --recursive with other options correctly' do
        args = ['/path/to/directory', '--search', 'keyword', '--label', 'processed', '--recursive']
        result = OptionsHandler.parse(args)

        expect(result[:options].search).to eq('keyword')
        expect(result[:options].label).to eq('processed')
        expect(result[:options].recursive).to be true
        expect(result[:directory]).to eq(File.expand_path('/path/to/directory'))
      end
    end

    context 'when invalid options are provided' do
      it 'exits and prints an error for missing directory' do
        args = ['--search', 'keyword', '--label', 'processed']
        expect do
          OptionsHandler.parse(args)
        end.to output(/Option Parsing Error: Specify exactly one directory/).to_stdout.and raise_error(SystemExit)
      end

      it 'exits and prints an error when --label is missing' do
        args = ['/path/to/directory', '--search', 'keyword']
        expect do
          OptionsHandler.parse(args)
        end.to output(/Error: '--label' and '--search' arguments are required/).to_stdout.and raise_error(SystemExit)
      end

      it 'exits and prints an error when --search is missing' do
        args = ['/path/to/directory', '--label', 'processed']
        expect do
          OptionsHandler.parse(args)
        end.to output(/Error: '--label' and '--search' arguments are required/).to_stdout.and raise_error(SystemExit)
      end

      it 'exits when more than one directory is given' do
        args = ['/path/to/directory1', '/path/to/directory2', '--search', 'keyword', '--label', 'processed']
        expect do
          OptionsHandler.parse(args)
        end.to output(/Option Parsing Error: Specify exactly one directory/).to_stdout.and raise_error(SystemExit)
      end

      it 'handles invalid options gracefully' do
        args = ['/path/to/directory', '--bad-option']
        expect do
          OptionsHandler.parse(args)
        end.to output(/Option Parsing Error: invalid option: --bad-option/).to_stdout.and raise_error(SystemExit)
      end
    end

    context 'when --list is provided' do
      it 'does not require --label or --search' do
        args = ['/path/to/directory', '--list']
        result = OptionsHandler.parse(args)

        expect(result[:options].list).to be true
        expect(result[:options].label).to be_nil
        expect(result[:options].search).to be_nil
        expect(result[:directory]).to eq(File.expand_path('/path/to/directory'))
      end

    end
  end
end