class myapp {
  package { "myapp-pkg":
    ensure => latest
  }
  if true { }
}
