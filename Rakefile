require "rake/testtask"
require "bundler/gem_tasks"
require "puppet/version"
require "rubygems"
require "yaml"
require "erb"

desc "Clean workspace"
task :clean do
  sh "rm -vrf *.gem pkg/"
  sh "rm test/cases/working-with-hiera/hiera.yaml"
  sh "rm test/cases/failing-with-hiera/hiera.yaml"
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :test_integration do
  base_dir = Dir.pwd
  all_tests_green = true

  Dir["test/**/Rakefile"].each do |rf|
    supposed_to_fail = rf.include?("failing")
    if rf.include?("future-parser")
      supposed_to_fail = Gem::Version.new(Puppet.version) > Gem::Version.new('3.2.0')
    end
    Dir.chdir rf.split("/")[0..-2].join("/")

    ["catalog:scenarios", "catalog:all"].each do |tc|
      tc_name = "#{rf} / #{tc}"
      puts " * Running scenario: #{tc_name} ]"

      exit_code = -1
      captured_output = ""

      if FileTest.exist?("hiera.yaml.erb")
        template = ERB.new(File.read("hiera.yaml.erb"))
        working_directory = File.join(File.dirname(__FILE__), File.dirname(rf))

        File.open("hiera.yaml", "w") do |fp|
          fp.puts template.result(binding)
        end
      end

      IO.popen("bundle exec rake #{tc}") do |io|
        while (line = io.gets)
          captured_output << line
        end

        io.close
        exit_code = $?
      end

      if (supposed_to_fail && exit_code != 0) || (!supposed_to_fail && exit_code == 0)
        puts "    WORKED (supposed_to_fail = #{supposed_to_fail})"
      else
        all_tests_green = false
        puts "\tScenario: #{tc_name} FAILED (supposed_to_fail = #{supposed_to_fail})"
        puts ">>>>>>>>>>>>>"
        puts captured_output
        puts "<<<<<<<<<<<<<"
      end
    end

    Dir.chdir base_dir
  end

  if !all_tests_green
    fail
  end
end

task :generate_test_matrix do
  # rbenv doesn't support fuzzy version matching, so we are using a good old mapping table
  ruby_version_mapping =  {
    "1.8.7" => "1.8.7-p374",
    "1.9.3" => "1.9.3-p551",
    "2.0.0" => "2.0.0-p645"
  }

  config = YAML.load_file(".travis.yml")
  checks = []

  config["rvm"].each do |ruby_version|
    config["env"].each do |env_var|
      if !config["matrix"]["exclude"].detect { |ex| ex["rvm"] == ruby_version && ex["env"] == env_var }
        puppet_version = env_var.match(/^PUPPET_VERSION=(.*)$/)[1]
        mapped_ruby_version = ruby_version_mapping[ruby_version] || ruby_version
        checks << "check #{mapped_ruby_version} #{puppet_version}"
      end
    end
  end

  template = ERB.new(File.read("run-all-tests.erb"))
  File.open("run-all-tests", "w+") { |fp| fp.puts template.result(binding) }
end

task :default => [:test, :test_integration]
