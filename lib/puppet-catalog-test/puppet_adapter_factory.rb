require "puppet/version"
require "puppet-catalog-test/puppet_adapter/base_puppet_adapter"

require "puppet-catalog-test/puppet_adapter/puppet_3x_adapter"
require "puppet-catalog-test/puppet_adapter/puppet_4x_adapter"

module PuppetCatalogTest
  class PuppetAdapterFactory
    def self.create_adapter(config)
      if Puppet.version.start_with?("3.")
        return Puppet3xAdapter.new(config)
      elsif Puppet.version.start_with?("4.")
        return Puppet4xAdapter.new(config)
      elsif Puppet.version.start_with?("5.")
        return Puppet4xAdapter.new(config)
      end

      raise RuntimeException, "Unsupported Puppet version detected (#{Puppet.version})"
    end
  end
end
