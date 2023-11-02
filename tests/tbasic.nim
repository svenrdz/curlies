
import std/unittest

import curlies

type
  Person = object
    name: string
    age, height: int
    favouriteNumber: int = 3

const
  name = "Sam"
  age = 30
  height = 160
  favouriteNumber = 12
  expectedSamFav3 = Person(
    name: name,
    age: age,
    height: height,
  )
  expectedSamFav12 = Person(
    name: name,
    age: age,
    height: height,
    favouriteNumber: favouriteNumber
  )

block:
  ## setting all fields works as expected
  let
    sam = Person{ name: "Sam", age: 30, height: 160, favouriteNumber: 12 }
  check sam == expectedSamFav12

block:
  ## omitting default value is fine
  let
    sam = Person{ name: "Sam", age: 30, height: 160 }
  check sam == expectedSamFav3

block:
  ## using a variable sharing a field name produces a hint
  ## Hint: field name can be omitted: 'name: name' -> 'name'
  let
    sam = Person{ name: name, age: 30, height: 160 }
  check sam == expectedSamFav3

block:
  ## in this case the field can be omitted
  let
    sam = Person{ name, age: 30, height: 160 }
  check sam == expectedSamFav3

block:
  ## any field can be omitted
  let
    sam = Person{ name, age, height, favouriteNumber }
  check sam == expectedSamFav12

block:
  ## fields can be given in whatever order
  let
    sam = Person{ age, favouriteNumber, height, name }
  check sam == expectedSamFav12

block:
  ## all fields must be given (except those with default values)
  check not compiles(Person{ name })
  check compiles(Person{ name, age, height })

block:
  ## positional arguments are not supported
  check not compiles(Person{ name, 30, height })
  let someAge = 30
  check not compiles(Person{ name, someAge, height })
  ## but any variable name is fine as long as the field name is given
  let sam = Person{ name, age: someAge, height }
  check sam == expectedSamFav3

block:
  ## does multi-line work? of course
  let
    sam = Person{
      name,
      age,
      height,
      favouriteNumber,
    }
  check sam == expectedSamFav12

block:
  ## expressions can be used as long as field name is specified
  let
    sam = Person{
      name,
      age: 10 * 3,
      height,
      favouriteNumber: (
        var x = 0
        for _ in 0..<12:
          x += 1
        x
      ),
    }
  check sam == expectedSamFav12
