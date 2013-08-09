node "foo" {
  include myapp
}

node default {
  include myapp

  notify { 'tc_hiera_failing':
    message => hiera('message_that_doesnt_exist')
  }
}
