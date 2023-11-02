import micros/[nimnodes, nimnames]
import micros/definitions/identdefs

type
  Field* = object
    name*: NimName
    value*: NimNode
  Fields* = seq[Field]

proc `$`*(field: Field): string =
  when false:
    let start = "Field[" & $field.name
    case field.kind
    of Curli:
      start & ": " & $field.value.repr & "]"
    else:
      start & "]"
  else:
    "Field[" & $field.name & ": " & $field.value.repr & "]"

proc symFields*(sym: NimNode{sym}): Fields =
  let
    impl = sym.getImpl[2]
    exprlist = case impl.kind:
      of nnkObjConstr:
        impl[1..^1]
      of nnkTupleConstr:
        impl[0..^1]
      else:
        error("bad kind " & $impl.kind)
        impl[0..0]
  for expr in exprlist:
    result.add Field(name: expr[0].nimName, value: expr[1])

proc `[]`*(fields: Fields, name: NimName): NimNode =
  for field in fields:
    if field.name == name:
      return field.value
  return newEmptyNode()

proc contains*(fields: Fields, name: NimName): bool =
  fields[name].kind != nnkEmpty

proc has*(fields: Fields, name: NimName, val: NimNode): bool =
  let
    hasDefault = val.kind != nnkEmpty
  hasDefault or name in fields

proc has*(fields: Fields, iDef: IdentDef): bool =
  let
    hasDefault = iDef.val.kind != nnkEmpty
  hasDefault or iDef.name in fields

proc isZeroDefault*(field: Field): bool =
  (field.value.kind == nnkCall) and
  (field.value[0].kind == nnkSym) and
  (field.value[0].strVal == "zeroDefault")
