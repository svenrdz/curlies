import curlies
import ./check

type
  Person[T: SomeInteger] = object
    name: string
    age: T
    favouriteNumber: int = 3

const
  name = "Alice"
  age = 30'u8
  alice = Person[uint8](name: name, age: age, favouriteNumber: 3)

block:
  ## generic object
  check Person[uint8]{name, age} == alice
  check not compiles(Person{name, age})

block:
  ## update syntax
  let bob = Person[uint8]{name: "Bob", ..alice}
  check bob == Person[uint8](name: "Bob", age: 30, favouriteNumber: 3)
