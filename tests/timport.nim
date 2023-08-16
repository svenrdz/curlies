
import std/unittest

import curlies

import ./module

const
  name = "Sam"
  age = 30
  favouriteNumber = 12

block:
  check not compiles(SomePerson{ })
  check not compiles(SomePerson{ age })
  check compiles(SomePerson{ name })

block:
  let sam = SomePerson{ name }
  check sam == SomePerson(name: name, favouriteNumber: 3)

block:
  let sam = SomePerson{ name, favouriteNumber }
  check sam == SomePerson(name: name, favouriteNumber: 12)
