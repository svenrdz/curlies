
import std/unittest

import curlies

type
  Person[T: SomeInteger] = object
    name: string
    age: T
    favouriteNumber: int = 3

const
  name = "Sam"
  age = 30'u8
  sam = Person[uint8](name: name, age: age, favouriteNumber: 3)

# block:
#   ## generic object
#   check Person[uint8]{ name, age } == sam
#   check not compiles(Person{name, age})

block:
  ## update syntax
  let max = Person[uint8]{ name: "Max", ..sam }
  check max == Person[uint8](name: "Max", age: 30, favouriteNumber: 3)
