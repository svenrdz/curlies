
when defined(nimscript):
  template check(x: bool) = assert x
  template expect(a, b: untyped) = discard
else:
  import std/unittest

import curlies
import fungus
import std/macros

adtEnum(Shape):
  None
  Circle: tuple[x, y, r: int]
  Rectangle: tuple[x, y, w, h: int]

type
  RegularCircle = object
    x, y, r: int

const regularCircle = RegularCircle(x: 1, y: 2, r: 3)

block:
  ## field shorthand
  let
    x = 1
    y = 2
    r = 3
    c = Circle{ x, y, r }
  check c.x == 1
  check c.y == 2
  check c.r == 3
  assert c is Circle # check doesn't work here

block:
  ## update syntax from regular object
  let
    c = Circle{ ..regularCircle }
  check c.x == 1
  check c.y == 2
  check c.r == 3
  assert c is Circle # check doesn't work here

block:
  ## update syntax from fungus object (same branch)
  let
    c1 = Circle.init(1, 2, 3)
    c2 = Circle{ ..c1 }
  check c2.x == 1
  check c2.y == 2
  check c2.r == 3
  assert c2 is Circle # check doesn't work here


block:
  ## update syntax from fungus object (branch switch)
  let
    c = Circle.init(1, 2, 3)
    r = Rectangle{ w: 3, h: 4, ..c }
  check r.x == 1
  check r.y == 2
  check r.w == 3
  check r.h == 4
  assert r is Rectangle

# block:
#   ## update syntax from fungus object (using base) -> not supported
#   let
#     c = Shape Circle.init(1, 2, 3)
#     r = Rectangle{ w: 3, h: 4, ..c }
#   check r.x == 1
#   check r.y == 2
#   check r.w == 3
#   check r.h == 4
#   assert r is Rectangle
