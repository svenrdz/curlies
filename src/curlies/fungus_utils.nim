import std/[macros, macrocache]
import curlies/def

const adtTable = CacheTable"FungusTable"

proc hashName(n: NimNode): string =
  if n.kind == nnkBracketExpr:
    n[0].signatureHash
  else:
    n.signatureHash

proc isAdt(t: DefObj): bool =
  t.obj[0].hashName() in adtTable

proc isAdtBase(t: DefObj): bool =
  t.isAdt() and t.quality == @[Object]

proc isAdtChild*(t: DefObj): bool =
  t.isAdt() and t.quality == @[Distinct, Object]
