$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "test/unit"
require "mocha/setup"

require "puppet-catalog-test"

CASE_DIR = File.join(File.dirname(__FILE__), "cases")

class PuppetCatalogTestCase < Test::Unit::TestCase
  def setup
    Puppet.settings.instance_eval("clear_everything_for_tests")
  end

  def default_test
    # required by mocha + ruby 1.8.7
  end

  def build_test_runner(base_dir)
    out_buffer = StringIO.new

    puppet_config = {
      :manifest_path => File.join(base_dir, "site.pp"),
      :module_paths => [File.join(base_dir, "modules")],
      :config_dir => base_dir,
      :hiera_config => hiera_config(base_dir)
    }

    runner_config = {}

    pct = PuppetCatalogTest::TestRunner.new(puppet_config, out_buffer, runner_config)

    pct.exit_on_fail = false

    pct
  end

  def hiera_config(base_dir)
    hiera_path = File.join(File.dirname(File.expand_path(__FILE__)), "..", base_dir)
    hiera_yml = File.join(hiera_path, "hiera.yaml")

    return hiera_yml if FileTest.exists?(hiera_yml)
    nil
  end

  def build_test_runner_for_all_nodes(base_dir, empty_facts = false, filter = PuppetCatalogTest::Filter.new)
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
