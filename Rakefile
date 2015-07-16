require "rake/testtask"
require "bundler/gem_tasks"

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
    Dir.chdir rf.split("/")[0..-2].join("/")

    ["catalog:scenarios", "catalog:all"].each do |tc|
      tc_name = "#{rf} / #{tc}"
      puts " * Running scenario: #{tc_name} ]"

      exit_code = -1
      captured_output = ""

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

task :default => [:test, :test_integration]
