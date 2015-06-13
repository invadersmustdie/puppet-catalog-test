require "puppet"

module PuppetCatalogTest
  class Puppet4xAdapter < BasePuppetAdapter
    def initialize(config)
      super(config)

      @env = Puppet.lookup(:current_environment).
        override_with(:manifest => config[:manifest_path]).
        override_with(:modulepath => config[:module_paths])

      require 'puppet/test/test_helper'

      Puppet::Test::TestHelper.initialize
      Puppet::Test::TestHelper.before_all_tests
    end

    def version
      Puppet.version
    end

    def nodes
      @env.known_resource_types.nodes.keys
    end

    def create_node(hostname, facts)
      Puppet::Node.new(hostname, :facts => Puppet::Node::Facts.new("facts", facts))
    end

    def compile(node)
      begin
        Puppet::Test::TestHelper.before_each_test
        Puppet::Parser::Compiler.compile(node)
      rescue => e
        raise e
      ensure
        Puppet::Test::TestHelper.after_each_test
      end
    end
  end
end
