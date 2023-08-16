import std/[genasts, macros]
import curlies/[curliable, construct, check, errors]

macro `{}`*(T: typedesc[Curliable], params: varargs[untyped]): untyped =
  runnableExamples:
    type
      SomePerson = object
        name: string
        age, height: int
        favouriteNumber: int = 3

    let
      name = "Sam"
      age = 30
      sam = SomePerson{ name, age, height: 160 }
      height = 155
      max = SomePerson{
        name: "Max",
        height,
        ..sam
      }
    echo sam
    # (name: "Sam", age: 30, height: 160, favouriteNumber: 3)
    echo max
    # (name: "Max", age: 30, height: 155, favouriteNumber: 3)

  let
    originId = registerNode(T)
    (obj, dotdotId) = construct(T, params)
    dotdot = getNode(dotdotId)

  ## The expr stores `obj` in `tmp` so it is a symbol defined in the scope
  ## calling `T{}`.
  ## This enables using `.module()` on `tmp` and decide whether to require all
  ## fields or only exported ones.
  ## After checking the object's completeness, the expression is rewritten
  ## to a single nnkObjConstr, removing the temporary variable.
  result = genAst(obj, dotdot, dotdotId, originId):
    checkAndRewrite((var tmp = obj; tmp), dotdot, dotdotId, originId)
