
import std/unittest

import curlies

type
  SomePerson = object
    name: string
    age: int
    favouriteNumber: int = 3

const
  name = "Sam"
  age = 30

block `Should work with ref objects too`:
  type
    RefPerson = ref SomePerson
  let
    sam = RefPerson{ name, age }
  check sam[] == SomePerson(name: "Sam", age: 30, favouriteNumber: 3)
  check not compiles(RefPerson{ })

block `multi ref is not (yet?) supported`:
  type
    RefRefPerson = ref ref SomePerson
  check not compiles(RefRefPerson{ name, age })
