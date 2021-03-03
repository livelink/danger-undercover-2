# frozen_string_literal: true

module Danger
  # Report missing coverage report using undercover and danger-undercover
  #
  # You have to use [undercover](https://github.com/grodowski/undercover) to gather
  # undercover report and send the report to this plugin so that danger-undercover
  # can use it.
  #
  # @example Report missing coverage report
  #
  #          undercover.report('coverage/undercover.txt')
  #
  # @see  nimblehq/danger-undercover
  # @tags ruby, code-coverage, simplecov, undercover, danger, simplecov-lcov
  #
  class DangerUndercover < Plugin
    VALID_FILE_FORMAT = '.txt'
    DEFAULT_PATH = 'coverage/undercover.txt'
    MAX_INLINE_COMMENTS = 30
    MAX_CHARACTERS_PER_MESSAGE = 60_000

    # Checks the file validity and fails if no file is found.
    # If a valid file is found, the content of it will be parsed according to options
    # and reports will be sent to danger.
    #
    # Options
    #   - *undercover_path* the path to the undercover.txt file.
    #     Defaults to `coverage/undercover.txt`.
    #   - *sticky* from (danger)[https://danger.systems/reference.html].
    #     Defaults to `true`.
    #   - *in_line* when `true` will report each line or block missing coverage as an in-line comment.
    #     Defaults to `false`.
    #   - *report_danger* when `true` will report a failure to danger when new code is at 0 test coverage.
    #     Defaults to `false`, so it generates warnings instead.
    #   - *max_inline_comments* determine the maximum number of reported messages.
    #     Used to avoid Github API abuse mechanism.
    #     When limit is reached, a custom message is added to inform the user.
    #     Defaults to MAX_INLINE_COMMENTS.
    #
    # @return  [void]
    #
    def report(undercover_path = DEFAULT_PATH, sticky: true, in_line: false, report_danger: false, max_inline_comments: MAX_INLINE_COMMENTS)
      return fail('Undercover: coverage report cannot be found.') unless valid_file? undercover_path

      report = File.open(undercover_path).read.force_encoding('UTF-8')

      # Returns and add a message if is all good.
      return message(cut_report(report), sticky: sticky) unless report.match(/some methods have no test coverage/)

      # Returns the content of the report unless `in_line` option is true
      return report_with_type(report_danger, cut_report(report), sticky) unless in_line

      reported_inline_comments = 0

      report.each_line do |line|
        next unless line.strip.start_with?("loc:")

        reported_inline_comments += 1
        _, filename, from_line, to_line = *line.match(/loc:\s([^:]+):(\d+):(\d+)/)
        warn("Coverage reported 0 hits #{line}", file: filename, line: from_line.to_i, sticky: sticky)

        if reported_inline_comments >= max_inline_comments
          summary_message = "The maximum number of in-line comments for 0 test" \
                            " coverage has been reached.\n" \
                            "Fix the reported issues to see more."

          break
        end
      end

      summary_message ||= "#{reported_inline_comments} reported issues with test coverage."
      report_with_type(report_danger, summary_message, sticky)
    end

    private

    # Checks if the file exists and the file is valid
    # @return [Boolean] File validity
    #
    def valid_file?(undercover_path)
      File.exist?(undercover_path) && (File.extname(undercover_path) == VALID_FILE_FORMAT)
    end

    # Cuts the undercover report to MAX_CHARACTERS_PER_MESSAGE of characters,
    # to stay below the `65_536` characters. Also adds elipses to make it clear
    # to viewers that the content was truncated.
    # Check https://github.com/danger/danger/issues/756
    # @return [Void]
    #
    def cut_report(report)
      return report if report.size <= MAX_CHARACTERS_PER_MESSAGE

      report[0..MAX_CHARACTERS_PER_MESSAGE] + " ... [Message Truncated]"
    end

    # Report message as `fail` or `warn` depending on `report_danger` value
    # @return [Void]
    #
    def report_with_type(report_danger, message, sticky)
      if report_danger
        fail(message, sticky: sticky)
      else
        warn(message, sticky: sticky)
      end
    end
  end
end
