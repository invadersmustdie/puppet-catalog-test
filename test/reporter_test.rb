load "test/test_helper.rb"

class ReporterTest < PuppetCatalogTestCase
  def test_mocked_reporter
    mocked_reporter = mock

    pct = build_test_runner_for_all_nodes(File.join(CASE_DIR, "working"))
    pct.reporter = mocked_reporter

    mocked_reporter.expects(:report_passed_test_case).times(0..2)
    mocked_reporter.expects(:summarize)

    result = pct.run_tests!
    assert result

    assert_equal 2, pct.test_cases.select { |tc| tc.passed }.size
  end
end
