import std/macros
import micros/[nimnodes, nimnames]

proc module*(n: NimNode): NimNode =
  if n.kind == nnkBracketExpr:
    result = n[0]
  else:
    result = n
  while result.symKind != nskModule:
    result = result.owner

func isPostfixStar*(name: NimNode): bool =
  name.kind == nnkPostfix and name[0] == ident"*"

func isPostfixStar*(name: NimName): bool =
  name.NimNode.isPostfixStar

func stripPostfix*(name: NimNode): NimNode =
  if name.isPostfixStar:
    name[1]
  else:
    name

func stripPostfix*(name: NimName): NimName =
  name.NimNode.stripPostfix.nimName
