import curlies
import ./[check, module]

const
  name = "Alice"
  age = 30
  email = "user@curli.es"
  favouriteNumber = 12

## Person is defined as:
# type
#   Person* = object
#     name*: string
#     age: int
#     favouriteNumber*: int = 3

block:
  ## errors on missing required fields
  check not compiles(Person{})

block:
  ## errors on non-exported fields
  check not compiles(Person{age})

block:
  ## compiles when all non-default, exported, fields are provided
  check compiles(Person{name})

block:
  ## default values are preserved
  let alice = Person{name}
  check alice == Person(name: name, favouriteNumber: 3)

block:
  ## default values can still be set as expected
  let alice = Person{name, favouriteNumber}
  check alice == Person(name: name, favouriteNumber: 12)

block:
  ## case object, errors on unexported fields
  let user = User{name, email}
  check not compiles(Account{})
  check not compiles(Account{..user})
  check not compiles(Account{kind: Free, ..user})
  check not compiles(Account{kind: Free, nbRequests: 0, unexportedField: 1.5, ..user})
  check compiles(Account{kind: Free, nbRequests: 0, ..user})
