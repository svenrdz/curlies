import curlies
import ./check

type Person = tuple[name: string, age: int, favouriteNumber: int = 3]

const
  name = "Alice"
  age = 30

block:
  ## tuple works as expected
  let alice = Person{name, age}
  check alice is Person
  check alice == (name, age, 3)
  check not compiles(Person{})

block:
  ## curlies even reorders fields to match the tuple
  let alice = Person{age, name}
  check alice is Person
  check alice == (name, age, 3)

block:
  ## updating works as expected
  let
    alice = (age: age, name: name)
    bob = Person{name: "Bob", ..alice}
    bob2 = Person{..bob}
  check bob is Person
  check bob == ("Bob", age, 3)
  check bob2 is Person
  check bob2 == bob
