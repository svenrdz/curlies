# Curlies

A macro for object construction using `{}` (curlies).

With curlies, initialization of <i>required</i> fields is checked at compile-time.
For object fields with a default value (available since nim 2.0),
initialization is obviously not mandatory.

It's simply a macro equivalent for the common `proc init[T](_: type T, ...)`
that uses the type's declaration to dispatch and check all required fields
are provided.
The output of a curlies construction is an [object construction] expression,
no temporary variables are introduced.


## But why?

I wanted to get a better grasp of nim's macro system and see how far it could
be pushed to enable static checks on missing fields for object initialization.


## Installation

Install curlies with [nimble]:

    $ nimble install curlies

Alternatively, curlies can be installed with [atlas]:

    $ atlas use curlies


## Syntax

Curlies is defined as a typed macro:

```nim
macro `{}`*(T: typedesc, params: varargs[untyped]): untyped
```

It's somehow similar to rust's struct initialization syntax, the main difference
being you cannot use a whitespace between the type and opening bracket `{`.

Borrowed features include:
* [field init shorthand]
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

* [update syntax]
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
* [generic objects](/tests/tgeneric.nim)
* [distinct objects](/tests/tdistinct.nim)
* [variant objects](/tests/tcase.nim)
* [inheritance objects](/tests/tinherit.nim)
* [tuples](/tests/ttuple.nim)
* even [fungus ADTs](/tests/tfungus.nim)!

Curlies behaviour differs based on the module where it is used.
* for types declared in the *same module*, **all non-default** fields are enforced.
* for types declared in *another module*, only **exported fields** are enforced,
unless of course they bring a default value.


## Usage

### Equivalent to regular object construction:

```nim
type
  Person = object
    name: string
    age, height: int
    favouriteNumber: int = 3

const
  alice = Person{
    name: "Alice",
    age: 30,
    height: 175
  }

echo alice
# (name: "Alice", age: 30, height: 175, favouriteNumber: 3)
```


### Field init shorthand + update syntax

```nim
type
  Person = object
    name: string
    age, height: int
    favouriteNumber: int = 3

let
  name = "Bob"
  height = 155
  bob = Person{
    name,
    height,
    ..alice,
  }
echo bob
# (name: "Bob", age: 30, height: 155, favouriteNumber: 3)
```

### Compilation error on missing fields

```nim
type
  Person = object
    name: string
    age, height: int
    favouriteNumber: int = 3

echo Person{ name: "Incomplete" }
# Error: @[age, height]: initialization required.
```

[object construction]: https://nim-lang.org/docs/manual.html#types-object-construction
[field init shorthand]: https://doc.rust-lang.org/stable/book/ch05-01-defining-structs.html#using-the-field-init-shorthand
[update syntax]: https://doc.rust-lang.org/stable/book/ch05-01-defining-structs.html#creating-instances-from-other-instances-with-struct-update-syntax
[tests]: /tests
[nimble]: https://github.com/nim-lang/nimble
[atlas]: https://github.com/nim-lang/atlas
[micros]: https://github.com/beef331/micros
