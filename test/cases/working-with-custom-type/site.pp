node "foo" {
  include myapp
}

node default {
  include myapp

  test { 'testing_requires':}
}
