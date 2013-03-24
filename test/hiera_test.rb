load "test/test_helper.rb"
require "erb"

class HieraTest < PuppetCatalogTestCase
  def test_hiera_should_work
    working_directory = "FOOBAR"
    template = ERB.new(File.read(File.join(CASE_DIR, "working-with-hiera", "hiera.yaml.erb")))

    File.open(File.join(CASE_DIR, "working-with-hiera", "hiera.yaml"), "w") do |fp| 
      fp.puts template.result(binding)
    end

    pct = build_test_runner_for_all_nodes(File.join(CASE_DIR, "working-with-hiera"))

    assert_equal 2, pct.test_cases.size

    result = pct.run_tests!
    assert result

    puts "WORKING"
    pct.test_cases.each do |tc|
      p tc
    end

    assert_equal 2, pct.test_cases.select { |tc| tc.passed == true }.size
  end

  def test_hiera_should_fail
    pct = build_test_runner_for_all_nodes(File.join(CASE_DIR, "failing-with-hiera"))

    assert_equal 2, pct.test_cases.size

    result = pct.run_tests!
    assert !result

    puts "FAILING"
    pct.test_cases.each do |tc|
      p tc
    end

    assert pct.test_cases.detect { |tc| tc.passed == false && tc.error =~ /Could not find data item message_that_doesnt_exist in any Hiera data file and no default/ }
  end
end
