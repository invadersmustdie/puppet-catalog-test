module PuppetCatalogTest
  class StdoutReporter
    def initialize(stdout_target = $stdout)
      @out = stdout_target
    end

    def report_passed_test_case(tc)
      @out.puts "[PASSED]  #{tc.name} (compile time: #{tc.duration} seconds)"
    end

    def report_failed_test_case(tc)
      @out.puts "[FAILED]  #{tc.name} (compile time: #{tc.duration} seconds)"
    end

    def summarize(test_run)
      failed_cases = test_run.test_cases.select { |tc| tc.passed == false }
      avg_time = test_run.total_duration / test_run.test_cases.size

      @out.puts
      @out.puts "-" * 40

      @out.puts "Compiled %d catalogs in %.4f seconds (avg: %.4f seconds)" % [
        test_run.test_cases.size,
        test_run.total_duration,
        avg_time
      ]

      if !failed_cases.empty?
        @out.puts "#{failed_cases.size} test cases failed."
        @out.puts

        failed_cases.each do |tc|
          @out.puts " [F] #{tc.name}:"
          @out.puts "     #{tc.error}"
          @out.puts
        end

        @out.puts "#{failed_cases.size} / #{test_run.test_cases.size} FAILED"
      end
    end
  end
end
