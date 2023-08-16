
import std/unittest

import curlies

type
  SomePerson = object
    name: string
    age, height: int
    favouriteNumber: int = 3

const
  name = "Sam"
  age = 30
  height = 160
  favouriteNumber = 12
  expectedSamFav3 = SomePerson(
    name: name,
    age: age,
    height: height,
  )
  expectedSamFav12 = SomePerson(
    name: name,
    age: age,
    height: height,
    favouriteNumber: favouriteNumber
  )

block:
  ## setting all fields works as expected
  let
    sam = SomePerson{ name: "Sam", age: 30, height: 160, favouriteNumber: 12 }
  check sam == expectedSamFav12

block:
  ## omitting default value is fine
  let
    sam = SomePerson{ name: "Sam", age: 30, height: 160 }
  check sam == expectedSamFav3

block:
  ## using a variable sharing a field name produces a hint
  ## Hint: field name can be omitted: 'name: name' -> 'name'
  let
    sam = SomePerson{ name: name, age: 30, height: 160 }
  check sam == expectedSamFav3

block:
  ## in this case the field can be omitted
  let
    sam = SomePerson{ name, age: 30, height: 160 }
  check sam == expectedSamFav3

block:
  ## any field can be omitted
  let
    sam = SomePerson{ name, age, height, favouriteNumber }
  check sam == expectedSamFav12

block:
  ## fields can be given in whatever order
  let
    sam = SomePerson{ age, favouriteNumber, height, name }
  check sam == expectedSamFav12

block:
  ## all fields must be given (except those with default values)
  check not compiles(SomePerson{ name })
  check compiles(SomePerson{ name, age, height })

block:
  ## positional arguments are not supported
  check not compiles(SomePerson{ name, 30, height })
  let someAge = 30
  check not compiles(SomePerson{ name, someAge, height })
  ## but any variable name is fine as long as the field name is given
  let sam = SomePerson{ name, age: someAge, height }
  check sam == expectedSamFav3

block:
  ## does multi-line work? of course
  let
    sam = SomePerson{
      name,
      age,
      height,
      favouriteNumber,
    }
  check sam == expectedSamFav12

block:
  ## expressions can be used as long as field name is specified
  let
    sam = SomePerson{
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
