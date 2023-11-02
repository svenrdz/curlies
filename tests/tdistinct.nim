
import std/unittest

import curlies

type
  Person = object
    name: string
    age: int
    favouriteNumber: int = 3

const
  name = "Sam"
  age = 30

block:
  ## distinct object
  type
    DistinctPerson = distinct Person
  let
    sam = DistinctPerson{name, age}
  check sam is DistinctPerson
  check Person(sam) == Person(name: "Sam", age: 30, favouriteNumber: 3)
  check not compiles(DistinctPerson{})

block:
  ## combining ref with distinct (still no multi ref)
  type
    RefPerson = ref Person
    DistinctRefPerson = distinct RefPerson
  check compiles(RefPerson{name, age})
  check not compiles(DistinctRefPerson{name, age})
