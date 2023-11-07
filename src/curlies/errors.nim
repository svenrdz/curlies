import std/[macros, macrocache]

const mcErrorNodes = CacheTable"errorNodes"

proc registerNode*(n: NimNode): string =
  var n = n
  if n.kind notin {nnkSym, nnkIdent}:
    n = n.findChild(it.kind in {nnkSym, nnkIdent})
  let id = genSym(ident = $n).repr
  mcErrorNodes[id] = n
  id

proc getNode*(id: string): NimNode =
  if id in mcErrorNodes:
    copyNimNode mcErrorNodes[id]
  else:
    newLit(true)

proc getNode*(id: NimNode): NimNode =
  getNode id.strVal

macro errorNode*(msg: static string, id: string) =
  let node = getNode(id)
  error(msg, node)
