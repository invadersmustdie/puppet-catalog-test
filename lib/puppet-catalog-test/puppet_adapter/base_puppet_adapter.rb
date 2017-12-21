require "puppet"

module PuppetCatalogTest
  class BasePuppetAdapter
    def initialize(config)
      @config = config
    end
    
    def init_config()
      config = @config
      manifest_path = config[:manifest_path]
      module_paths = config[:module_paths]
      config_dir = config[:config_dir]
      hiera_config = config[:hiera_config]
      verbose = config[:verbose]

      raise ArgumentError, "[ERROR] manifest_path must be specified" if !manifest_path
      raise ArgumentError, "[ERROR] manifest_path (#{manifest_path}) does not exist" if !FileTest.exist?(manifest_path)

      raise ArgumentError, "[ERROR] module_path must be specified" if !module_paths
      module_paths.each do |mp|
        raise ArgumentError, "[ERROR] module_path (#{mp}) does not exist" if !FileTest.directory?(mp)
      end

      if config_dir
        Puppet.settings.handlearg("--confdir", config_dir)
      end

      if verbose
        Puppet::Util::Log.newdestination(:console)
        Puppet::Util::Log.level = :debug
      end

      Puppet.settings.handlearg("--config", ".")
      Puppet.settings.handlearg("--manifest", manifest_path)

      module_path = module_paths.join(":")

      Puppet.settings.handlearg("--modulepath", module_path)

      if hiera_config
        raise ArgumentError, "[ERROR] hiera_config  (#{hiera_config}) does not exist" if !FileTest.exist?(hiera_config)
        Puppet.settings[:hiera_config] = hiera_config
      end
    end

    def parser; end
    def compile(node); end
    def create_node(hostname, facts); end
    def version; end
    def prepare; end
    def cleanup; end
  end
end
