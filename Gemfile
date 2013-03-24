source :rubygems

puppetversion = ENV.key?('PUPPET_VERSION') ? "= #{ENV['PUPPET_VERSION']}" : ['>= 2.7']

gem "rake"
gem "puppet", puppetversion
gem "builder"

gem "hiera"
gem "hiera-puppet"

group :test do
  gem "mocha", :require => false
end
