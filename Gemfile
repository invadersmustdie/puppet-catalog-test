source :rubygems

puppetversion = ENV.key?('PUPPET_VERSION') ? "= #{ENV['PUPPET_VERSION']}" : ['>= 2.7']

gem "rake"
gem "puppet", puppetversion
gem "builder"
gem "parallel"

group :test do
  gem "mocha", "~> 0.13", :require => false
end
