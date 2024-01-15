import std/[genasts, macros]
import curlies/[construct, check, errors]

macro `{}`*(T: typedesc, params: varargs[untyped]): untyped =
  runnableExamples:
    type
      Person = object
        name: string
        age, height: int
        favouriteNumber: int = 3

    let
      name = "Alice"
      age = 30
      alice = Person{name, age, height: 160}
      height = 155
      bob = Person{name: "Bob", height, ..alice}

    echo alice
    # (name: "Alice", age: 30, height: 160, favouriteNumber: 3)
    echo bob
    # (name: "Bob", age: 30, height: 155, favouriteNumber: 3)

  let
    originId = registerNode(T)
    (obj, final, dotdotId) = construct(T, params)
    dotdot = getNode(dotdotId)

  ## The `tmp` variable represents a regular variable defined using an object
  ## construct expression, using a type pruned of all ref/distinct modifiers.
  ## The `final` node holds the actual expression with the correct type.
  ## This enables using the `module` proc and the `fields` iterator on `tmp`
  ## as it is a symbol.
  ## After checking the object's completeness, the expression is rewritten
  ## to the single `final` expression, with additional fields from `..`, and
  ## effectively removing any temporary variable.
  result =
    genAst(obj, final, dotdot, dotdotId, originId):
      checkAndRewrite((var tmp = obj; tmp), final, dotdot, dotdotId, originId)
