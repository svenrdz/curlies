### DISCLAIMER

This library is an experiment, and comes with heavier compilation times, a basic
benchmark is provided at the end of this file.

I recommend NOT to use it in a production environment.


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


## Compilation times

I compared compiling `tests/tbasic.nim` with its equivalent that uses regular
object construction `tests/tbasic_nocurlies.nim`, numbers below:

* With latest stable
```shell
$ nim -v
Nim Compiler Version 2.0.2 [Linux: amd64]
Compiled at 2023-12-15
Copyright (c) 2006-2023 by Andreas Rumpf

git hash: c4c44d10df8a14204a75c34e499def200589cb7c
active boot switches: -d:release

$ hyperfine \
    'nim c -f --hints:off -o:/tmp/tbasic tests/tbasic.nim' \
    'nim c -f --hints:off -o:/tmp/tbasic tests/tbasic_nocurlies.nim'
Benchmark 1: nim c -f --hints:off -o:/tmp/tbasic tests/tbasic.nim
  Time (mean ± σ):      1.707 s ±  0.051 s    [User: 3.175 s, System: 0.706 s]
  Range (min … max):    1.652 s …  1.799 s    10 runs

Benchmark 2: nim c -f --hints:off -o:/tmp/tbasic tests/tbasic_nocurlies.nim
  Time (mean ± σ):      1.557 s ±  0.031 s    [User: 3.003 s, System: 0.699 s]
  Range (min … max):    1.505 s …  1.587 s    10 runs

Summary
  nim c -f --hints:off -o:/tmp/tbasic tests/tbasic_nocurlies.nim ran
    1.10 ± 0.04 times faster than nim c -f --hints:off -o:/tmp/tbasic tests/tbasic.nim
```


* With latest devel
```shell
$ nim -v
Nim Compiler Version 2.1.1 [Linux: amd64]
Compiled at 2024-01-14
Copyright (c) 2006-2024 by Andreas Rumpf

git hash: ab4278d2179639f19967431a7aa1be858046f7a7
active boot switches: -d:release

$ hyperfine \
    'nim c -f --hints:off -o:/tmp/tbasic tests/tbasic.nim' \
    'nim c -f --hints:off -o:/tmp/tbasic tests/tbasic_nocurlies.nim'
Benchmark 1: nim c -f --hints:off -o:/tmp/tbasic tests/tbasic.nim
  Time (mean ± σ):      2.805 s ±  0.271 s    [User: 5.384 s, System: 2.553 s]
  Range (min … max):    2.447 s …  3.368 s    10 runs

Benchmark 2: nim c -f --hints:off -o:/tmp/tbasic tests/tbasic_nocurlies.nim
  Time (mean ± σ):      2.252 s ±  0.230 s    [User: 4.615 s, System: 1.920 s]
  Range (min … max):    2.061 s …  2.741 s    10 runs

Summary
  nim c -f --hints:off -o:/tmp/tbasic tests/tbasic_nocurlies.nim ran
    1.25 ± 0.18 times faster than nim c -f --hints:off -o:/tmp/tbasic tests/tbasic.nim
```

On my computer, curlies comes with **10 to 25% slower compilation**, depending
on the compiler version.

Well this is an experiment anyway, I must advise against using it in a production environment.

[object construction]: https://nim-lang.org/docs/manual.html#types-object-construction
[field init shorthand]: https://doc.rust-lang.org/stable/book/ch05-01-defining-structs.html#using-the-field-init-shorthand
[update syntax]: https://doc.rust-lang.org/stable/book/ch05-01-defining-structs.html#creating-instances-from-other-instances-with-struct-update-syntax
[tests]: /tests
[nimble]: https://github.com/nim-lang/nimble
[atlas]: https://github.com/nim-lang/atlas
[micros]: https://github.com/beef331/micros
