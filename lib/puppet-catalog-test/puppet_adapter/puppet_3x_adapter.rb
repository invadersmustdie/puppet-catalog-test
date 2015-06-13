require "puppet"

module PuppetCatalogTest
  class Puppet3xAdapter < BasePuppetAdapter
    def initialize(config)
      super(config)

      Puppet.parse_config
    end

    def nodes
      parser = Puppet::Parser::Parser.new(Puppet::Node::Environment.new)
      parser.known_resource_types.nodes.keys
    end

    def compile(node)
      Puppet::Parser::Compiler.compile(node)
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
