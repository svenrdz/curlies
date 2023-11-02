
import std/unittest

import curlies

import ./module

const
  name = "Sam"
  age = 30
  favouriteNumber = 12

block:
  check not compiles(Person{ })
  check not compiles(Person{ age })
  check compiles(Person{ name })

block:
  let sam = Person{ name }
  check sam == Person(name: name, favouriteNumber: 3)

block:
  let sam = Person{ name, favouriteNumber }
  check sam == Person(name: name, favouriteNumber: 12)
