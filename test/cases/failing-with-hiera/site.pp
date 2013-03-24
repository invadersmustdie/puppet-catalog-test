node "foo" {
  include myapp
}

node default {
  include myapp

  $missing_key = hiera('message_that_doesnt_exist')
}
