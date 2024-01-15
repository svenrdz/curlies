## Enables running tests within nimscript

when defined(nimscript):
  template check*(x: bool) =
    assert x

else:
  import std/unittest
  export unittest
