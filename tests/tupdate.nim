import curlies
import ./check

type
  User = object
    name, email: string

  UserWithLoginInfo = object
    name, email: string
    isLogged: bool = false

const
  name = "user"
  email = "user@curli.es"
  user = User(name: name, email: email)
  loggedUser = UserWithLoginInfo(name: name, email: email, isLogged: true)

block:
  ## `update missing fields with `..` syntax`
  let otherUser = User{email: "another@curli.es", ..user}
  check otherUser == User(name: name, email: "another@curli.es")

block:
  ## fields with default value are NOT updated
  let unloggedUser = UserWithLoginInfo{..loggedUser}
  check loggedUser.isLogged
  check not unloggedUser.isLogged

block:
  ## update missing fields with any object
  type
    Person = object
      name: string
      age: int
      favouriteNumber: int = 3

  let
    alice = Person(name: "Alice", age: 30)
    aliceUser = User{email: "alice@curli.es", ..alice}
  check aliceUser == User(name: "Alice", email: "alice@curli.es")

block:
  ## error: updating from an object that does not have all missing fields
  type
    Unrelated = object
      a, b: int

  let unrelated = Unrelated(a: 1, b: 2)
  check not compiles(User{..unrelated})
