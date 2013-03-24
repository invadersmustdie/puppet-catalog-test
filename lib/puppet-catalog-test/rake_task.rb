require 'rake'
require 'rake/tasklib'

module PuppetCatalogTest
  class RakeTask < ::Rake::TaskLib
    include ::Rake::DSL if defined?(::Rake::DSL)

    attr_accessor :module_paths
    attr_accessor :manifest_path
    attr_accessor :scenario_yaml
    attr_accessor :filter
    attr_accessor :facts
    attr_accessor :reporter

    def initialize(name, &task_block)
      desc "Compile all puppet catalogs" unless ::Rake.application.last_comment

      @filter = PuppetCatalogTest::DEFAULT_FILTER

      task name do
        task_block.call(self) if task_block
        setup
      end
    end

    def setup
      puppet_config = {
        :manifest_path => @manifest_path,
        :module_paths => @module_paths
      }

      pct = TestRunner.new(puppet_config)

      if @scenario_yaml
        pct.load_scenario_yaml(@scenario_yaml, @filter)
      else
        nodes = pct.collect_puppet_nodes(@filter)
        test_facts = @facts || fallback_facts

        nodes.each do |nodename|
          facts = test_facts.merge({
            'hostname' => nodename,
            'fqdn' => "#{nodename}.localdomain"
          })

          pct.add_test_case(nodename, facts)
        end
      end

      pct.reporter = @reporter if @reporter

      pct.run_tests!
    end

    private

    def fallback_facts
      {
        'architecture' => 'x86_64',
        'ipaddress' => '127.0.0.1',
        'local_run' => 'true',
        'disable_asserts' => 'true',
        'interfaces' => 'eth0'
      }
    end
  end
end
