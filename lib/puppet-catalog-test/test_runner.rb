require "yaml"
require "puppet"
require "parallel"

require "puppet-catalog-test/test_case"
require "puppet-catalog-test/stdout_reporter"

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

      @reporter = StdoutReporter.new(stdout_target)

      @total_duration = nil

      manifest_path = puppet_config[:manifest_path]
      module_paths = puppet_config[:module_paths]
      config_dir = puppet_config[:config_dir]
      hiera_config = puppet_config[:hiera_config]
      verbose = puppet_config[:verbose]

      raise ArgumentError, "[ERROR] manifest_path must be specified" if !manifest_path
      raise ArgumentError, "[ERROR] manifest_path (#{manifest_path}) does not exist" if !FileTest.exist?(manifest_path)

      raise ArgumentError, "[ERROR] module_path must be specified" if !module_paths
      module_paths.each do |mp|
        raise ArgumentError, "[ERROR] module_path (#{mp}) does not exist" if !FileTest.directory?(mp)
      end

      if config_dir
        Puppet.settings.handlearg("--confdir", config_dir)
      end

      if verbose == 1
          Puppet::Util::Log.newdestination(:console)
          Puppet::Util::Log.level = :debug
      end

      Puppet.settings.handlearg("--config", ".")
      Puppet.settings.handlearg("--config", ".")
      Puppet.settings.handlearg("--manifest", manifest_path)

      module_path = module_paths.join(":")

      Puppet.settings.handlearg("--modulepath", module_path)

      if hiera_config:
        raise ArgumentError, "[ERROR] hiera_config  (#{hiera_config}) does not exist" if !FileTest.exist?(hiera_config)
        Puppet.settings[:hiera_config] = hiera_config
      end

      Puppet.parse_config
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

      node = Puppet::Node.new(hostname)
      node.merge(facts)

      Puppet::Parser::Compiler.compile(node)
    end

    def collect_puppet_nodes(filter)
      parser = Puppet::Parser::Parser.new("environment")
      nodes = parser.environment.known_resource_types.nodes.keys

      if filter.exclude_pattern
        nodes.delete_if { |node| node.match(filter.exclude_pattern) }
      end

      if filter.include_pattern
        nodes.delete_if { |node| !node.match(filter.include_pattern) }
      end

      nodes
    end

    def run_tests!
      @out.puts "[INFO] Using puppet #{Puppet::PUPPETVERSION}"

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
          p error if $DEBUG
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
