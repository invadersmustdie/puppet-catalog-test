class myapp {
  package { "myapp-pkg":
    ensure => latest
  }
  unless $fqdn { fail('$fqdn unset') }
}
