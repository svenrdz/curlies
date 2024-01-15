import curlies
import ./check

type
  Person = object
    name: string
    age: int
    favouriteNumber: int = 3

  DistinctPerson = distinct Person

const
  name = "Alice"
  age = 30

block:
  ## distinct object
  let alice = DistinctPerson{name, age}
  check alice is DistinctPerson
  check Person(alice) == Person(name: "Alice", age: 30, favouriteNumber: 3)
  check not compiles(DistinctPerson{})

block:
  ## update syntax
  let
    distinctAlice = DistinctPerson{name, age}
    alice = Person distinctAlice
    bob = DistinctPerson{name: "Bob", ..alice}
  check bob is DistinctPerson
  check Person(bob) == Person(name: "Bob", age: 30, favouriteNumber: 3)
  check not compiles(DistinctPerson{name: "Bob", ..distinctAlice})

# block:
#   ## combining ref with distinct (still no multi ref)
#   type
#     RefPerson = ref Person
#     DistinctRefPerson = distinct RefPerson
#   check compiles(RefPerson{ name, age })
#   check not compiles(DistinctRefPerson{ name, age })
