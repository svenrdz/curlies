# Curlies

A macro for object construction using `{}` (curlies).

## But why?

Curlies enforces initialization of all <i>required</i> fields, those that don't
have a default value.

It's basically a compile-time equivalent for `proc init[T](...)` that uses the
type's definition to verify all fields are supplied, and produces an [object
construction] expression.

## Installation

Install curlies with [nimble]:

    $ nimble install curlies

Alternatively, curlies can be installed with [atlas]:

    $ atlas use curlies

## Syntax

Curlies are defined as a typed macro:

```nim
macro `{}`*(T: typedesc[Curliable], params: varargs[untyped]): untyped
```

It's very similar to rust's struct initialization syntax, the main difference
being you cannot use a whitespace between the type and opening bracket `{`.

Borrowed features include:
* [field init shorthand]:
```nim
type
  MyType = object
    myField: int
let
  myField = 1
  full = MyType{ myField: myField }
  short = MyType{ myField }
assert full == short
```

* [update syntax]:
```nim
type
  MyType = object
    a, b, c: int
let
  original = MyType(a: 1, b: 2, c: 3)
  derived = MyType{ a: 4, ..original }
assert derived == MyType(a: 4, b: 2, c: 3)
```

## Supported

Most nim types should work out of the box, [tests] currently cover:

* [objects](/tests/tbasic.nim)
* [ref objects](/tests/tref.nim)
* [variant objects](/tests/tcase.nim)
* [inheritance objects](/tests/tinherit.nim)

For types imported from another module, only exported fields are enforced,
unless of course they bring a default value. Otherwise, all non-default fields
are enforced.

## Usage

### Equivalent to regular object construction:

```nim
type
  SomePerson = object
    name: string
    age, height: int
    favouriteNumber: int = 3

const
  sam = SomePerson{
    name: "Sam",
    age: 30,
    height: 175
  }

echo sam
# (name: "Sam", age: 30, height: 175, favouriteNumber: 3)
```


### Field init shorthand + update syntax

```nim
type
  SomePerson = object
    name: string
    age, height: int
    favouriteNumber: int = 3

let
  name = "Max"
  height = 155
  max = SomePerson{
    name,
    height,
    ..sam,
  }
echo max
# (name: "Max", age: 30, height: 155, favouriteNumber: 3)
```

### Compilation error on missing fields

```nim
type
  SomePerson = object
    name: string
    age, height: int
    favouriteNumber: int = 3

echo SomePerson{ name: "Incomplete" }
# Error: @[age, height]: initialization required.
```

[object construction]: https://nim-lang.org/docs/manual.html#types-object-construction
[field init shorthand]: https://doc.rust-lang.org/stable/book/ch05-01-defining-structs.html#using-the-field-init-shorthand
[update syntax]: https://doc.rust-lang.org/stable/book/ch05-01-defining-structs.html#creating-instances-from-other-instances-with-struct-update-syntax
[tests]: /tests
[nimble]: https://github.com/nim-lang/nimble
[atlas]: https://github.com/nim-lang/atlas
[micros]: https://github.com/beef331/micros
