class myapp {
  package { "myapp-pkg":
    ensure => latest
  }

  test { 'testing_requires':}
}
