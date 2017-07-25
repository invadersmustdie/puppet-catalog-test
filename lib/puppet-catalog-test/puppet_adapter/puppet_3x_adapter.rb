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
      begin
        catalog = Puppet::Parser::Compiler.compile(node)
        validate_relationships(catalog)
      rescue => e
        raise e
      ensure
        Puppet::Test::TestHelper.after_each_test
      end
    end

    def create_node(hostname, facts)
      Puppet::Test::TestHelper.before_each_test
      node = Puppet::Node.new(hostname)
      node.merge(facts)
      node
    end

    def version
      Puppet::PUPPETVERSION
    end

    def validate_relationships(catalog)
      catalog.resources.each do |resource|
        next unless resource.is_a?(Puppet::Resource)

        resource.each do |param, value|
          pclass = Puppet::Type.metaparamclass(param)
          if !pclass.nil? && pclass < Puppet::Type::RelationshipMetaparam
            next if value.is_a?(String)
            check_if_resource_exists(catalog, resource, param, value)
          end
        end
      end
      nil
    end

    private

    def check_if_resource_exists(catalog, resource, param, value)
      case value
      when Array
        value.each { |v| check_if_resource_exists(catalog, resource, param, v) }
      when Puppet::Resource
        matching_resource = catalog.resources.find do |resource|
          resource.type == value.type &&
            (resource.title.to_s == value.title.to_s ||
             resource[:name] == value.title ||
             resource[:alias] == value.title)
        end

        unless matching_resource
          fail "#{resource} has #{param} relationship to invalid resource #{value}"
        end
      end
    end
  end
end
