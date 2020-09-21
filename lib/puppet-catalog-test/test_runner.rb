require "yaml"
require "parallel"

require "puppet-catalog-test/test_case"
require "puppet-catalog-test/stdout_reporter"
require "puppet-catalog-test/puppet_adapter_factory"

module PuppetCatalogTest
  class TestRunner
    attr_accessor :exit_on_fail
    attr_accessor :reporter

    attr_reader :test_cases
    attr_reader :total_duration

    def initialize(puppet_config, stdout_target = $stdout)
      if !puppet_config
        raise ArgumentError, "No puppet_config hash supplied"
      end

      @test_cases = []
      @exit_on_fail = true
      @out = stdout_target
      @puppet_adapter = PuppetAdapterFactory.create_adapter(puppet_config)

      if puppet_config[:xml]
        require 'puppet-catalog-test/junit_xml_reporter'
        @reporter = PuppetCatalogTest::JunitXmlReporter.new("puppet-catalog-test", "puppet_catalogs.xml")
      else
        @reporter = StdoutReporter.new(stdout_target)
      end

      @total_duration = nil
    end

    def load_scenario_yaml(yaml_file, filter = nil)
      scenarios = YAML.load_file(yaml_file)

      scenarios.each do |tc_name, facts|
        next if tc_name =~ /^__/

        if filter
          next if filter.exclude_pattern && tc_name.match(filter.exclude_pattern)
          next if filter.include_pattern && !tc_name.match(filter.include_pattern)
        end

        add_test_case(tc_name, facts)
      end
    end

    def load_all(filter = Filter.new, facts = {})
      nodes = collect_puppet_nodes(filter)

      nodes.each do |n|
        node_facts = facts.dup

        if !node_facts.has_key?('fqdn')
          node_facts['fqdn'] = n
        end

        add_test_case(n, node_facts)
      end
    end

    def add_test_case(tc_name, facts)
      tc = TestCase.new
      tc.name = tc_name
      tc.facts = facts

      @test_cases << tc
    end

    def compile_catalog(node_fqdn, facts = {})
      hostname = node_fqdn.split('.').first
      facts['hostname'] = hostname

      node = @puppet_adapter.create_node(node_fqdn, facts)

      @puppet_adapter.compile(node)
    end

    def collect_puppet_nodes(filter)
      nodes = @puppet_adapter.nodes

      if filter.exclude_pattern
        nodes.delete_if { |node| node.match(filter.exclude_pattern) }
      end

      if filter.include_pattern
        nodes.delete_if { |node| !node.match(filter.include_pattern) }
      end

      nodes
    end

    def run_tests!
      @out.puts "[INFO] Using puppet #{@puppet_adapter.version}"

      run_start = Time.now
      proc_count = Parallel.processor_count

      processed_test_cases = Parallel.map(@test_cases, :in_processes => proc_count) do |tc|
        begin
          tc_start_time = Time.now

          if tc.facts['fqdn'].nil?
            raise "fact 'fqdn' must be defined"
          else
            compile_catalog(tc.facts['fqdn'], tc.facts)
            tc.duration = Time.now - tc_start_time

            tc.passed = true

            @reporter.report_passed_test_case(tc)
          end
        rescue => error
          if $DEBUG
            p error
            puts e.backtrace
          end

          tc.duration = Time.now - tc_start_time
          tc.error = error.message
          tc.passed = false

          @reporter.report_failed_test_case(tc)
        end

        tc
      end

      @test_cases = processed_test_cases

      @total_duration = Time.now - run_start

      @reporter.summarize(self)

      if test_cases.any? { |tc| tc.passed == false }
        exit 1 if @exit_on_fail
        return false
      end

      true
    end
  end
end
