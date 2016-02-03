[![Build Status](https://travis-ci.org/invadersmustdie/puppet-catalog-test.png?branch=master)](https://travis-ci.org/invadersmustdie/puppet-catalog-test)
[![Code Climate](https://codeclimate.com/github/invadersmustdie/puppet-catalog-test.png)](https://codeclimate.com/github/invadersmustdie/puppet-catalog-test)
[![Gem Version](https://badge.fury.io/rb/puppet-catalog-test.png)](http://badge.fury.io/rb/puppet-catalog-test)

# Test all your puppet catalogs for compiler warnings and errors

puppet-catalog-test is a tool for capturing and testing warnings and errors the puppet-compiler is emitting during the compilation process.

For a more detailed insight into the puppet-compiler, you can take a look at <http://www.masterzen.fr/2012/03/17/puppet-internals-the-compiler/>.

## Supported Ruby + Puppet Versions

Supported versions of Ruby <> Puppet combinations are listed in the [support matrix](SUPPORTED_VERSIONS.md). Combinations not listed might work, but aren't tested yet.

## Installation

    gem install puppet-catalog-test

## Usage
```bash
$ puppet-catalog-test -h
USAGE: puppet-catalog-test [options]
    -m, --module-paths PATHS         Location of puppet modules, separated by collon
    -M, --manifest-path PATH         Location of the puppet manifests (site.pp)
    -H, --hiera-config PATH          Location of hiera.yaml file
    -i, --include-pattern PATTERN    Include only test cases that match pattern
    -e, --exclude-pattern PATTERN    Exclude test cases that match pattern
    -s, --scenario FILE              Scenario definition to use
    -f, --fact KEY=VALUE             Add custom fact
    -p, --parser (current|future)    Change puppet parser (3.x only)
    -v, --verbose                    Verbose
    -x, --xml                        Use xml report
    -h, --help                       Show this message
```
## Examples

### CLI - successfull compile run
```bash
$ puppet-catalog-test -m test/cases/working/modules -M test/cases/working/site.pp
[INFO] Using puppet 3.0.2
[PASSED]  foo (compile time: 0.168182 seconds)
[PASSED]  default (compile time: 0.003451 seconds)

----------------------------------------
Compiled 2 catalogs in 0.1717 seconds (avg: 0.0858 seconds)
```

### CLI - failed compile run
```bash
$ puppet-catalog-test -m test/cases/failing/modules -M test/cases/failing/site.pp
[INFO] Using puppet 3.0.2
[FAILED]  foo (compile time: 0.17113 seconds)
[FAILED]  default (compile time: 0.002951 seconds)

----------------------------------------
Compiled 2 catalogs in 0.1741 seconds (avg: 0.0871 seconds)
2 test cases failed.

 [F] foo:
     Duplicate declaration: Package[myapp-pkg] is already declared in file /Users/rlengwin/devel/github/puppet-catalog-test/test/cases/failing/modules/myapp/manifests/init.pp at line 4; cannot redeclare on node foo

 [F] default:
     Duplicate declaration: Package[myapp-pkg] is already declared in file /Users/rlengwin/devel/github/puppet-catalog-test/test/cases/failing/modules/myapp/manifests/init.pp at line 4; cannot redeclare on node default

2 / 2 FAILED
```

## Rake integration

### Testing all catalogs with default facts

When not setting any filters or scenarios puppet-catalog-test will test all nodes defined in site.pp.

```ruby
require 'puppet-catalog-test'

namespace :catalog do
  PuppetCatalogTest::RakeTask.new(:all) do |t|
    t.module_paths = ["modules"]
    t.manifest_path = File.join("scripts", "site.pp")

    t.include_pattern = ENV["include"]
    t.exclude_pattern = ENV["exclude"]

    t.verbose = true
  end
end
```

In the case above no facts weren't defined so puppet-catalog-test falls back to some basic facts to satisfy the most basic requirements of puppet. Currently these facts are:

```ruby
{
  'architecture' => 'x86_64',
  'ipaddress' => '127.0.0.1',
  'local_run' => 'true',
  'disable_asserts' => 'true',
  'interfaces' => 'eth0'
}
```

**NOTE:** Working examples are bundled within [test/cases](test/cases).

### Testing all catalogs with custom facts

It is also possible to define a custom set of facts. In this case the fallback facts listed in previous example won't be used.

*NOTE:* When using custom facts the fact 'fqdn' always has to be set!

```ruby
require 'puppet-catalog-test'

namespace :catalog do
  PuppetCatalogTest::RakeTask.new(:all) do |t|
    t.module_paths = ["modules"]
    t.manifest_path = File.join("scripts", "site.pp")
    t.facts = {
      "fqdn" => "foo.local",
      "operatingsystem" => "RedHat"
    }

    t.include_pattern = ENV["include"]
    t.exclude_pattern = ENV["exclude"]
  end
end
```

### Testing catalog with future parser
```ruby
require 'puppet-catalog-test'

namespace :catalog do
  PuppetCatalogTest::RakeTask.new(:scenarios) do |t|
    t.module_paths = ["modules"]
    t.manifest_path = File.join("scripts", "site.pp")

    t.scenario_yaml = "scenarios.yml"
    t.parser = "future"

    t.include_pattern = ENV["include"]
    t.exclude_pattern = ENV["exclude"]
  end
```

## Scenario testing

Scenarios allow testing of more complex catalogs, e.g. having conditional branches depending on custom facts.

```ruby
require 'puppet-catalog-test'

namespace :catalog do
  PuppetCatalogTest::RakeTask.new(:scenarios) do |t|
    t.module_paths = [File.join("modules")]
    t.manifest_path = File.join("scripts", "site.pp")

    t.scenario_yaml = "scenarios.yml"

    t.include_pattern = ENV["include"]
    t.exclude_pattern = ENV["exclude"]
  end
end
```

```yaml
__default_facts: &default_facts
  architecture: x86_64
  ipaddress: 127.0.0.1
  operatingsystem: SLES
  operatingsystemrelease: 11
  local_run: true
  disable_asserts: true
  interfaces: eth0

SLES_tomcat:
  <<: *default_facts
  fqdn: tomcat-a001.foo.local

REDHAT_tomcat:
  <<: *default_facts
  fqdn: tomcat-a001.foo.local
  operatingsystem: RedHat

SLES_db-dev:
  <<: *default_facts
  fqdn: db-a001.foo.local

REDHAT_db-dev:
  <<: *default_facts
  fqdn: db-a001.foo.local
  operatingsystem: RedHat
```

*NOTE:* Scenarios starting with two underscores (like __default_facts) will be ignored.

## Reporters (output plugins)

Per default puppet-catalog-test uses the StdoutReporter which prints the result like in the examples above. Besides this you can use in your own Reporter.

Puppet-Catalog-Test also ships a JunitXmlReporter which creates a junit compatible xml report.

```ruby
require 'puppet-catalog-test'
require 'puppet-catalog-test/junit_xml_reporter'

namespace :catalog do
  PuppetCatalogTest::RakeTask.new(:all) do |t|
    t.module_paths = [File.join("modules")]
    t.manifest_path = File.join("scripts", "site.pp")

    t.reporter = PuppetCatalogTest::JunitXmlReporter.new("puppet-vagrant-playground", "reports/puppet_catalog.xml")
  end
end
```

## Testing with hiera

Hiera configuration is loaded by setting the **config_dir** parameter in rake task or using the **-H, --hiera-config PATH** switch.

```ruby
require 'puppet-catalog-test'
require 'puppet-catalog-test/junit_xml_reporter'

namespace :catalog do
  PuppetCatalogTest::RakeTask.new(:all) do |t|
    t.module_paths = [File.join("modules")]
    t.manifest_path = File.join("scripts", "site.pp")

    # crucial option for hiera integration
    t.config_dir = File.join("data") # expects hiera.yaml to be included in directory

    t.reporter = PuppetCatalogTest::JunitXmlReporter.new("puppet-vagrant-playground", "reports/puppet_catalog.xml")
  end
end
```

# Credits

Code is based upon the previous work done on https://github.com/oldNoakes/puppetTesting
