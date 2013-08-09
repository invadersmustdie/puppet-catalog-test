load "test/test_helper.rb"
require "erb"

class HieraTest < PuppetCatalogTestCase
  def setup_hiera(case_name)
    working_directory = File.join(File.dirname(__FILE__), "cases", case_name)
    template = ERB.new(File.read(File.join(CASE_DIR, case_name, "hiera.yaml.erb")))

    File.open(File.join(CASE_DIR, case_name, "hiera.yaml"), "w") do |fp|
      fp.puts template.result(binding)
    end
  end

  def test_hiera_should_work
    setup_hiera("working-with-hiera")

    pct = build_test_runner_for_all_nodes(File.join(CASE_DIR, "working-with-hiera"))

    assert_equal 2, pct.test_cases.size

    result = pct.run_tests!
    assert result

    assert_equal 2, pct.test_cases.select { |tc| tc.passed == true }.size
  end

  def test_hiera_should_fail
    setup_hiera("failing-with-hiera")

    pct = build_test_runner_for_all_nodes(File.join(CASE_DIR, "failing-with-hiera"))

    assert_equal 2, pct.test_cases.size

    result = pct.run_tests!
    assert !result

    assert pct.test_cases.detect { |tc| tc.passed == false && tc.error =~ /Could not find data item message_that_doesnt_exist in any Hiera data file and no default/ }

    assert_equal 1, pct.test_cases.select { |tc| tc.passed == true }.size
  end
end
