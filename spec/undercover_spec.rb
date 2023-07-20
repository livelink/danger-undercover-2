# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

module Danger
  describe Danger::DangerUndercover do
    it 'is a Danger plugin' do
      expect(Danger::DangerUndercover.new(nil)).to be_a Danger::Plugin
    end

    describe 'Dangerfile' do
      before do
        @dangerfile = testing_dangerfile
        @undercover = @dangerfile.undercover
      end

      it 'fails if file is not found' do
        @undercover.report('spec/fixtures/missing_file.txt')

        expect(@dangerfile.status_report[:errors]).to eq(['Undercover: coverage report cannot be found.'])
      end

      it 'shows success message if nothing to report' do
        report_path = 'spec/fixtures/undercover_passed.txt'
        @undercover.report(report_path)
        report = File.read(report_path)

        expect(@dangerfile.status_report[:messages]).to eq([report])
      end

      it 'shows warnings if undercover has a report' do
        report_path = 'spec/fixtures/undercover_failed.txt'
        @undercover.report(report_path)
        report = File.read(report_path)

        expect(@dangerfile.status_report[:warnings]).to eq([report])
      end

      context 'when report size exceeds 60k' do
        it 'reports a warning with a trimmered message' do
          report_path = 'spec/fixtures/undercover_failed_big.txt'
          @undercover.report(report_path)

          report = File.open(report_path).read
          warning = @dangerfile.status_report[:warnings].first

          expect(warning).to end_with('[Message Truncated]')
        end
      end

      context "when the in_line option is true" do
        it 'shows in-line warnings for each reported issue' do
          report_path = 'spec/fixtures/undercover_failed.txt'
          @undercover.report(report_path, in_line: true)

          expect(@dangerfile.status_report[:warnings].count).to eq(4)
        end

        context 'when the maximum number of in-line comments is reached' do
          it 'reports the maximum allowed of in-line comments and ' do
            report_path = 'spec/fixtures/undercover_failed.txt'
            @undercover.report(report_path, in_line: true, max_inline_comments: 1)

            expect(@dangerfile.status_report[:warnings].count).to eq(2)
          end
        end

        context "when report_danger option is true" do
          it 'reports 0 coverage as a failure' do
            report_path = 'spec/fixtures/undercover_failed.txt'
            @undercover.report(report_path, in_line: true, report_danger: true)

            report = File.open(report_path).read

            expect(@dangerfile.status_report[:errors].count).to eq(1)
          end
        end
      end
    end
  end
end
