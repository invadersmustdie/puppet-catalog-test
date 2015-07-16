require "puppet"

module PuppetCatalogTest
  class Puppet3xAdapter < BasePuppetAdapter
    def initialize(config)
      super(config)

      require 'puppet/test/test_helper'

      # works 3.7.x
      if version.start_with?("3.7.")
        Puppet::Test::TestHelper.initialize
      end

      Puppet::Node::Environment.new.modules_by_path.each do |_, mod|
        mod.entries.each do |entry|
          ldir = entry.plugin_directory
          $LOAD_PATH << ldir unless $LOAD_PATH.include?(ldir)
        end
      end

      Puppet.parse_config
    end

    def nodes
      parser = Puppet::Parser::Parser.new(Puppet::Node::Environment.new)
      parser.known_resource_types.nodes.keys
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

    def create_node(hostname, facts)
      node = Puppet::Node.new(hostname)
      node.merge(facts)
      node
    end

    def version
      Puppet::PUPPETVERSION
    end
  end
end
