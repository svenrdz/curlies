
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
  ## Should work with ref objects too
  type
    RefPerson = ref Person
  let
    sam = RefPerson{ name, age }
  check sam[] == Person(name: "Sam", age: 30, favouriteNumber: 3)
  check not compiles(RefPerson{ })

block:
  ## multi ref is not (yet?) supported
  type
    RefPerson = ref Person
    RefRefPerson = ref RefPerson
  check compiles(RefPerson{ name, age })
  check not compiles(RefRefPerson{ name, age })
