
import std/unittest

import curlies

type
  Person = object
    name: string
    age: int
    favouriteNumber: int = 3
  DistinctPerson = distinct Person

const
  name = "Sam"
  age = 30

block:
  ## distinct object
  let sam = DistinctPerson{ name, age }
  check sam is DistinctPerson
  check Person(sam) == Person(name: "Sam", age: 30, favouriteNumber: 3)
  check not compiles(DistinctPerson{})

block:
  ## update syntax
  let
    distinctSam = DistinctPerson{ name, age }
    sam = Person distinctSam
    max = DistinctPerson{ name: "Max", ..sam }
  check max is DistinctPerson
  check Person(max) == Person(name: "Max", age: 30, favouriteNumber: 3)
  check not compiles(DistinctPerson{ name: "Max", ..distinctSam })

# block:
#   ## combining ref with distinct (still no multi ref)
#   type
#     RefPerson = ref Person
#     DistinctRefPerson = distinct RefPerson
#   check compiles(RefPerson{ name, age })
#   check not compiles(DistinctRefPerson{ name, age })
