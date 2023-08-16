import std/macros
import micros/[nimnodes, nimnames]

proc module*(n: NimNode): NimNode =
  if n.kind == nnkBracketExpr:
    result = n[0]
  else:
    result = n
  while result.symKind != nskModule:
    result = result.owner

proc isExported*(name: NimName): bool =
  name.NimNode.kind == nnkPostfix and name.NimNode[0] == ident"*"

proc stripPostfix*(name: NimName): NimName =
  if name.isExported:
    name.NimNode[1].nimName
  else:
    name
