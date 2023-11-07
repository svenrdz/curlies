import std/[macros, strutils]
import ast_pattern_matching

type
  DefKind* = enum
    Object Ref Distinct Tuple Generic
  DefObj* = object
    obj*: NimNode
    quality*: seq[DefKind]

proc sym*(def: DefObj): NimNode =
  case def.obj.kind
  of nnkSym:
    def.obj
  of nnkTypeDef:
    def.obj[0]
  else:
    newNilLit()

proc `$`*(def: DefObj): string =
  let sym = case def.sym.kind:
    of nnkNilLit: "<Nil>"
    else: $def.sym
  result = dedent"""
  DefObj(
    sym: $1
    quality: $2
  $3)
  """ % [sym, $def.quality, indent(def.obj.repr, 2)]

proc `$`*(q: seq[DefKind]): string =
  q.join(" ").toLower

proc getDefImpl(def: var DefObj) =
  matchAst def.obj, errors:
  of `s` @ nnkSym:
    def.obj = s.getImpl
    getDefImpl def
  of `g` @ nnkBracketExpr(_, _):
    def.obj = g[0]
    def.quality.add Generic
    getDefImpl def
  of `r` @ nnkTypeDef(_, _, nnkRefTy):
    def.obj = r[2][0]
    def.quality.add Ref
    getDefImpl def
  of `d` @ nnkTypeDef(_, _, nnkDistinctTy):
    def.obj = d[2][0]
    def.quality.add Distinct
    getDefImpl def
  of `o` @ nnkTypeDef(_, _, nnkObjectTy):
    def.quality.add Object
  of `t` @ nnkTypeDef(_, _, nnkTupleTy):
    def.quality.add Tuple
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
