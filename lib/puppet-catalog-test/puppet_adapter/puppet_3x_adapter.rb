require "puppet"
require "rubygems"

module PuppetCatalogTest
  class Puppet3xAdapter < BasePuppetAdapter
    def initialize(config)
      super(config)

      require 'puppet/test/test_helper'
      parser = config[:parser]

      # initialize was added in 3.1.0
      if Gem::Version.new(version) > Gem::Version.new('3.1.0')
        Puppet::Test::TestHelper.initialize
      end

      Puppet::Node::Environment.new.modules_by_path.each do |_, mod|
        mod.entries.each do |entry|
          ldir = entry.plugin_directory
          $LOAD_PATH << ldir unless $LOAD_PATH.include?(ldir)
        end
      end

      # future parser was added in 3.2.0
      if parser and Gem::Version.new(version) > Gem::Version.new('3.2.0')
        parser_regex = /^(current|future)$/
        raise ArgumentError, "[ERROR] parser (#{parser}) is not a valid parser, should be 'current' or 'future'" if !parser.match(parser_regex)
        puts "[INFO] Using #{parser} puppet parser"
        Puppet.settings[:parser] = parser
      end

      Puppet.parse_config
    end

    def nodes
      parser = Puppet::Parser::Parser.new(Puppet::Node::Environment.new)
      parser.known_resource_types.nodes.keys
    end

    def compile(node)
      catalog = Puppet::Parser::Compiler.compile(node)
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
