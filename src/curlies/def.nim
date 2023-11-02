import std/[macros, strutils]
import ast_pattern_matching

type
  DefKind* = enum
    Object Ref Distinct
  DefObj* = object
    sym*: NimNode
    obj*: NimNode
    quality*: seq[DefKind]

proc `$`*(def: DefObj): string =
  result = dedent"""
  DefObj(
    sym: $1
    quality: $2
  $3)
  """ % [$def.sym, $def.quality, indent(def.obj.repr, 2)]

proc `$`*(q: seq[DefKind]): string =
  q.join(" ").toLower

proc getDefImpl(def: var DefObj) =
  matchAst def.obj, errors:
  of `s` @ nnkSym:
    def.sym = s
    def.obj = s.getImpl[2]
    getDefImpl def
  of `o` @ nnkObjectTy:
    def.quality.add Object
  of `r` @ nnkRefTy:
    def.obj = r[0]
    def.quality.add Ref
    getDefImpl def
  of `d` @ nnkDistinctTy:
    def.obj = d[0]
    def.quality.add Distinct
    getDefImpl def
  else:
    error($errors)

proc getDef*(x: NimNode): DefObj =
  result.obj = x
  getDefImpl result

when isMainModule:
  macro test[T](x: typedesc[T]) =
    let def = getDef x
    echo x.repr, " -> ", def
    echo ""
  type
    O = object
      x: int
    DO = distinct O
    R = ref object
      y: float
    DR = distinct R
    RO = ref O
    DRO = distinct RO
    RRRO = ref ref ref O
  test O
  test DO
  test R
  test DR
  test RO
  test DRO
  test RRRO
