
when defined(nimscript):
  template check(x: bool) = assert x
  template expect(a, b: untyped) = discard
else:
  import std/unittest

import curlies

type
  Person = tuple[
    name: string,
    age: int,
    favouriteNumber: int = 3
  ]

const
  name = "Sam"
  age = 30

block:
  ## tuple works as expected
  let
    sam = Person{name, age}
  check sam is Person
  check sam == (name, age, 3)
  check not compiles(Person{})

block:
  ## curlies even reorders fields to match the tuple
  let
    sam = Person{age, name}
  check sam is Person
  check sam == (name, age, 3)
  check not compiles(Person{})
