node "foo" {
  unless $fqdn { fail('$fqdn unset') }
}

node default {
  include myapp
}
