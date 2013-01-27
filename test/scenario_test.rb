load "test/test_helper.rb"

class ScenarioTest < PuppetCatalogTestCase
  def test_scenario_with_working_catalog_should_fail
    pct = build_test_runner(File.join(CASE_DIR, "working"))
    pct.load_scenario_yaml(File.join(CASE_DIR, "working", "scenarios.yml"))

    assert_equal 1, pct.test_cases.size

    result = pct.run_tests!
    assert result

    assert_equal 1, pct.test_cases.select { |tc| tc.passed == true }.size
  end

  def test_scenario_with_broken_catalog_should_fail
    pct = build_test_runner(File.join(CASE_DIR, "failing"))
    pct.load_scenario_yaml(File.join(CASE_DIR, "failing", "scenarios.yml"))

    assert_equal 2, pct.test_cases.size

    result = pct.run_tests!
    assert !result

    assert_equal 2, pct.test_cases.select { |tc| tc.passed == false }.size
  end

  def test_scenario_with_filter_should_work
    pct = build_test_runner(File.join(CASE_DIR, "failing"))
    pct.load_scenario_yaml(File.join(CASE_DIR, "failing", "scenarios.yml"), /foo/)

    assert_equal 1, pct.test_cases.size
  end
end
