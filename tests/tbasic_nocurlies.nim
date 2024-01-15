import ./check

type
  Person = object
    name: string
    age, height: int
    favouriteNumber: int = 3

const
  name = "Alice"
  age = 30
  height = 160
  favouriteNumber = 12
  expectedAliceFav3 = Person(name: name, age: age, height: height)
  expectedAliceFav12 =
    Person(name: name, age: age, height: height, favouriteNumber: favouriteNumber)

block:
  ## setting all fields works as expected
  let alice = Person(name: "Alice", age: 30, height: 160, favouriteNumber: 12)
  check alice == expectedAliceFav12

block:
  ## omitting default value is fine
  let alice = Person(name: "Alice", age: 30, height: 160)
  check alice == expectedAliceFav3

block:
  ## using a variable sharing a field name produces a hint
  ## Hint: field name can be omitted: 'name: name' -> 'name'
  let
    alice1 = Person(name: name, age: 30, height: 160)
    alice2 = Person(name: name, age: 30, height: 160)
  check alice1 == expectedAliceFav3
  check alice2 == expectedAliceFav3

block:
  ## any field can be omitted
  let
    alice =
      Person(name: name, age: age, height: height, favouriteNumber: favouriteNumber)
  check alice == expectedAliceFav12

block:
  ## fields can be given in whatever order
  let
    alice =
      Person(age: age, favouriteNumber: favouriteNumber, height: height, name: name)
  check alice == expectedAliceFav12

block:
  ## all fields must be given (except those with default values)
  check not compiles(Person(name))
  check compiles(Person(name: name, age: age, height: height))

block:
  ## positional arguments are not supported
  check not compiles(Person(name, 30, height))

  let someAge = 30
  check not compiles(Person(name, someAge, height))

  ## but any variable name is fine as long as the field name is given
  let alice = Person(name: name, age: someAge, height: height)
  check alice == expectedAliceFav3

block:
  ## does multi-line work? of course
  let
    alice =
      Person(
        name: name, # placehoder comment to force nph to keep multiline
        age: age,
        height: height,
        favouriteNumber: favouriteNumber,
      )
  check alice == expectedAliceFav12

block:
  ## expressions can be used as long as field name is specified
  # nph indenting is not yet optimal for curlies syntax
  # on the bright side, it only messes up in let/var sections
  let
    alice =
      Person(
        name: name,
        age: 10 * 3,
        height: height,
        favouriteNumber: (
          var x = 0
          for _ in 0..<12:
            x += 1
          x
        ),
      )
  check alice == expectedAliceFav12
