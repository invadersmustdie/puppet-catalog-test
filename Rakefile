require "rake/testtask"
require "bundler/gem_tasks"

desc "Clean workspace"
task :clean do
  sh "rm -vrf *.gem pkg/"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :default => :test
