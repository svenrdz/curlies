
import std/unittest

import curlies

type
  Person = object of RootObj
    name: string
    age: int
  User = object of Person
    email: string

const
  name = "Sam"
  age = 30
  email = "sam@curli.es"
let
  sam = Person(name: name, age: age)
  samUser = User(name: name, age: age, email: email)

block:
  let user = User{ name, age, email }
  check user == samUser

block:
  assert not compiles(User{ email })
  assert not compiles(User{ email, name })
  assert not compiles(User{ email, age })
  assert not compiles(User{ name, age })
  assert compiles(User{ name, age, email })

block:
  ## update syntax
  let
    max = Person{ name: "Max", age: 40 }
    maxUser = User{
      email: "max@curli.es",
      ..max
    }
  check maxUser == User(name: "Max", age: 40, email: "max@curli.es")
