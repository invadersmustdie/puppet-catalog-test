node "foo" {
  include myapp
}

node default {
  include myapp

  notify { 'tc_hiera_working':
    message => hiera('message')
  }
}
