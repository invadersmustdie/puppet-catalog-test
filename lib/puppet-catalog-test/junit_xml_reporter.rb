require "builder"

module PuppetCatalogTest
  class JunitXmlReporter < PuppetCatalogTest::StdoutReporter
    def initialize(project_name, report_file)
      @project_name = project_name
      @report_file = report_file

      target_dir = File.dirname(report_file)

      FileUtils.mkdir_p(target_dir)

      @out = $stdout
    end

    def summarize(tr)
      failed_nodes = tr.test_cases.select { |tc| tc.passed == false }
      builder = Builder::XmlMarkup.new

      xml = builder.testsuite(:failures => failed_nodes.size, :tests => tr.test_cases.size) do |ts|
        tr.test_cases.each do |tc|
          ts.testcase(:classname => @project_name, :name => tc.name, :time => tc.duration) do |tc_node|
            if tc.error
              tc_node.failure tc.error
            end
          end
        end
      end

      File.open(@report_file, "w") do |fp|
        fp.puts xml
      end
    end
  end
end
