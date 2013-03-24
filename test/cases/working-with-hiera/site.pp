node "foo" {
  include myapp
}

node default {
  include myapp

  $existing_key = hiera('message')
  notify {$existing_key: }
}
