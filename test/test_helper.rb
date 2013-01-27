$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "test/unit"
require "mocha/setup"

require "puppet-catalog-test"

CASE_DIR = File.join(File.dirname(__FILE__), "cases")

class PuppetCatalogTestCase < Test::Unit::TestCase
  def setup
    Puppet.settings.instance_eval("clear_everything_for_tests")
  end

  def build_test_runner(base_dir)
    out_buffer = StringIO.new

    pct = PuppetCatalogTest::TestRunner.new(
      File.join(base_dir, "site.pp"),
      [File.join(base_dir, "modules")],
      out_buffer
    )

    pct.exit_on_fail = false

    pct
  end

  def build_test_runner_for_all_nodes(base_dir, empty_facts = false, filter = /.*/)
    pct = build_test_runner(base_dir)

    if empty_facts
      pct.load_all(filter, {"fqdn" => nil})
    else
      pct.load_all(filter)
    end

    pct.exit_on_fail = false

    pct
  end
end
