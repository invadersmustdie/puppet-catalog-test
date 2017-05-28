#!/bin/bash

source /etc/profile.d/rvm.sh
ruby -v
type -p bundler || gem install bundler

cd /tmp
tar xzf /share/project.tar.gz
bundle install --path /cache/gems
bundle exec rake
echo "EXIT_STATUS=$?"
