require "yaml"
require "puppet"

require "puppet-catalog-test/test_case"
require "puppet-catalog-test/stdout_reporter"

module PuppetCatalogTest
  class TestRunner
    attr_accessor :exit_on_fail
    attr_accessor :reporter

    attr_reader :test_cases
    attr_reader :total_duration

    def initialize(manifest_path, module_paths, stdout_target = $stdout)
      @test_cases = []
      @exit_on_fail = true
      @out = stdout_target

      @reporter = StdoutReporter.new(stdout_target)

      @total_duration = nil

      raise ArgumentError, "[ERROR] manifest_path must be specified" if !manifest_path
      raise ArgumentError, "[ERROR] manifest_path (#{manifest_path}) does not exist" if !FileTest.exist?(manifest_path)

      raise ArgumentError, "[ERROR] module_path must be specified" if !module_paths
      module_paths.each do |mp|
        raise ArgumentError, "[ERROR] module_path (#{mp}) does not exist" if !FileTest.directory?(mp)
      end

      Puppet.settings.handlearg("--config", ".")
      Puppet.settings.handlearg("--manifest", manifest_path)

      module_path = module_paths.join(":")

      Puppet.settings.handlearg("--modulepath", module_path)

      Puppet.parse_config
    end

    def load_scenario_yaml(yaml_file, filter = nil)
      scenarios = YAML.load_file(yaml_file)

      scenarios.each do |tc_name, facts|
        next if tc_name =~ /^__/
        next if filter && !tc_name.match(filter)

        add_test_case(tc_name, facts)
      end
    end

    def load_all(filter = PuppetCatalogTest::DEFAULT_FILTER, facts = {})
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

      node = Puppet::Node.new(hostname)
      node.merge(facts)

      Puppet::Parser::Compiler.compile(node)
    end

    def collect_puppet_nodes(filter)
      parser = Puppet::Parser::Parser.new("environment")
      nodes = parser.environment.known_resource_types.nodes.keys
      nodes.select { |node| node.match(filter) }
    end

    def run_tests!
      @out.puts "[INFO] Using puppet #{Puppet::PUPPETVERSION}"

      run_start = Time.now

      @test_cases.each do |tc|
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
          tc.duration = Time.now - tc_start_time
          tc.error = error.message
          tc.passed = false

          @reporter.report_failed_test_case(tc)
        end
      end

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
