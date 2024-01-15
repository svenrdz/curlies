import curlies
import ./check

type
  Person = object of RootObj
    name: string
    age: int

  User = object of Person
    email: string

const
  name = "Alice"
  age = 30
  email = "alice@curli.es"

let
  alice = Person(name: name, age: age)
  aliceUser = User(name: name, age: age, email: email)

block:
  let user = User{name, age, email}
  check user == aliceUser

block:
  assert not compiles(User{email})
  assert not compiles(User{email, name})
  assert not compiles(User{email, age})
  assert not compiles(User{name, age})
  assert compiles(User{name, age, email})
block:
  ## update syntax
  let
    bob = Person{name: "Bob", age: 40}
    bobUser = User{email: "bob@curli.es", ..bob}
  check bobUser == User(name: "Bob", age: 40, email: "bob@curli.es")
