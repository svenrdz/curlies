import curlies
import ./check

type
  Person = object
    name: string
    age: int
    favouriteNumber: int = 3

const
  name = "Alice"
  age = 30

block:
  ## regular ref object
  type
    RefPerson = ref object
      name: string
      age: int

  let alice = RefPerson{name, age}
  check alice.name == "Alice"
  check alice.age == 30

block:
  ## lifted ref objects
  type RefPerson = ref Person

  let alice = RefPerson{name, age}
  check alice[] == Person(name: "Alice", age: 30, favouriteNumber: 3)
  check not compiles(RefPerson{})

block:
  ## update syntax
  type RefPerson = ref Person

  let
    alice = RefPerson{name, age}
    bob = RefPerson{name: "Bob", ..alice}
  check bob[] == Person(name: "Bob", age: 30, favouriteNumber: 3)

block:
  ## multi ref is not (yet?) supported
  type
    RefPerson = ref Person
    RefRefPerson = ref RefPerson

  check compiles(RefPerson{name, age})
  check not compiles(RefRefPerson{name, age})
