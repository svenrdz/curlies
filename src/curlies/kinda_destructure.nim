import std/[macros, tables, sequtils, strutils]
import micros/nimnodes
import micros/definitions/[identdefs, routines]

const
  x = "toto"
  y = "jojo"
  renamedY = "wowo"
  fromMacro = true

type
  GenericParam = object
    name: NimNode
    typ: NimNode
  Accessor = object
    path: seq[NimNode]
    args: seq[NimNode]
    rename: NimNode

proc `$`(gp: GenericParam): string =
  $gp.name & "[" & gp.typ.repr & "]"

proc hasType(gp: GenericParam): bool =
  gp.typ.kind != nnkEmpty

proc contains(gps: seq[GenericParam], name: NimNode): bool =
  for gp in gps:
    if gp.name == name:
      result = true
      break

proc `$`(acc: Accessor): string =
  acc.repr
  # "Acc(" & acc.args.mapIt($it).join(",") & " -> " & acc.path.mapIt($it).join(".") & " -> " & $acc.rename & ")"

# proc `[]`(gps: seq[GenericParam], name: NimNode): GenericParam =
#   for gp in gps:
#     if gp.name == name:
#       result = gp
#       break

# proc curliable(gps: seq[GenericParam], name: NimNode): bool =
#   name in gps and not gps[name].hasType

proc curliable(gps: seq[GenericParam]): seq[GenericParam] =
  for gp in gps:
    if not gp.hasType:
      result.add gp

# IdentDefs
#   Ident "_"
#   Empty
#   TableConstr
#     ExprColonExpr
#       Ident "x"
#       TableConstr
#         ExprColonExpr
#           Ident "y"
#           Ident "renamedY"

# proc newConcept: NimNode =
#   quote do:
#     type TheConcept = concept var theVar
#       discard

proc getGenericParams(routine: RoutineNode): seq[GenericParam] =
  for param in routine.genericParams:
    for name in param.names:
      result.add GenericParam(name: name.NimNode, typ: param.typ)

proc separateGenerics(routine: RoutineNode) =
  for param in routine.genericParams:
    let l = param.NimNode.len
    if l > 3:
      var first = true
      for name in param.names:
        if first:
          first = false
        else:
          routine.addGeneric identDef(name, param.val)
      param.NimNode.del(1, l - 3)

# ExprColonExpr
#   Ident "x"
#   TableConstr
#     ExprColonExpr
#       Ident "y"
#       Ident "ys"
#     Ident "others"

# proc makeDot(accessor: NimNode, curlies: NimNode, ignoreIdent = false): NimNode =
#   # echo accessor.repr
#   # echo curlies.treeRepr
#   case curlies.kind
#   of nnkCurlyExpr:
#     accessor.makeDot curlies[1]
#   of nnkIdent:
#     if ignoreIdent:
#       accessor
#     else:
#       newDotExpr(accessor, curlies)
#   of nnkExprColonExpr:
#     let dot = newDotExpr(accessor, curlies[0])
#     dot.makeDot(curlies[1], ignoreIdent = true)
#   of nnkTableConstr:
#     var dots = newStmtList()
#     for sub in curlies:
#       dots.add accessor.makeDot(sub)
#     dots
#   # of nnkStmtList:
#   #   accessor
#   else:
#     error("bad:\n" & accessor.repr & "\n" & curlies.treerepr, accessor)
#     newEmptyNode()
#   # echo expr.treerepr
#   # for name in expr

# proc fillConcept(c: NimNode, curlies: NimNode) =
#   let theVar = c[0][2][0][0][0]
#   let accessor = theVar.copyNimTree.makeDot(curlies)
#   # echo accessor.treerepr
#   c[0][^1][^1].add accessor

proc accessors(start: Accessor, curlies: NimNode, renameIdent = false): seq[Accessor] =
  case curlies.kind
  of nnkCurly:
    result.add start.accessors curlies[0]
  of nnkCurlyExpr:
    result.add start.accessors curlies[1]
  of nnkIdent:
    var start = start
    if not renameIdent:
      start.path.add curlies
    start.rename = curlies
    result.add start
  of nnkExprColonExpr:
    var start = start
    start.path.add curlies[0]
    result.add start.accessors(curlies[1], renameIdent = true)
  of nnkTableConstr:
    for sub in curlies:
      result.add start.accessors(sub)
  # of nnkStmtList:
  #   start
  else:
    error("bad:\n" & $start & "\n" & curlies.treerepr, start.path[^1])
  # echo expr.treerepr
  # for name in expr

# proc accessors(curlies: NimNode): seq[Accessor] =
#   Accessor().accessors(curlies)

proc accessors(idef: IdentDef): seq[Accessor] =
  result = Accessor().accessors(idef.val)
  for acc in result.mitems:
    for name in idef.names:
      acc.args.add name.NimNode

proc genDotExpr(acc: Accessor, node: NimNode): NimNode =
  result = node
  for dot in acc.path:
    result = newDotExpr(result, dot)

proc genConcept(accessors: seq[Accessor]): NimNode =
  result = quote do:
    type TheConcept = concept var theVar
  result[0][^1][^1] = newStmtList()
  let theVar = result[0][2][0][0][0]
  var done: seq[string]
  for acc in accessors:
    let node = acc.genDotExpr(theVar)
    # for dot in acc.path:
    #   node = newDotExpr(node, dot)
    if node.repr notin done:
      result[0][^1][^1].add node
      done.add node.repr
  # let accessor = theVar.copyNimTree.makeDot(curlies)
  # c[0][^1][^1].add accessor

proc genSymArgs(idef: IdentDef) =
  for i in 0 ..< idef.NimNode.len - 2:
    if idef.NimNode[i].eqIdent("_"):
      let tmp = quote do:
        let tmp = 0
      idef.NimNode[i] = tmp[0][0]

proc cleanup(idef: IdentDef) =
  idef.typ = idef.val[0]
  idef.val = newEmptyNode()

proc genLet(acc: Accessor): NimNode =
  var rhs = newNilLit()
  case acc.args.len
  of 1:
    rhs = acc.genDotExpr(acc.args[0])
  else:
    error("bad bad")
  result = newLetStmt(acc.rename, rhs)

proc rewriteProc(r: RoutineNode): NimNode =
  separateGenerics r
  let
    genericParams = r.getGenericParams
    curliable = genericParams.curliable
  var
    concepts = newTable[string, seq[Accessor]]()
    renames: seq[string]
  for idef in r.params:
    if idef.val.kind == nnkCurlyExpr:
      let name = idef.val[0]
      if name notin curliable:
        error("Cannot use " & $name & " with curlies, its type is already set.", name)
      genSymArgs idef
      concepts.mgetOrPut($name, @[]).add idef.accessors
      cleanup idef
  result = newStmtList()
  for key, accs in concepts:
    let body = accs.genConcept
    for acc in accs:
      if $acc.rename in renames:
        error("`" & $acc.rename & "` cannot be used twice", acc.rename)
      renames.add $acc.rename
      r.body.NimNode.insert(0, acc.genLet)
      # add name fields
      discard
    for g in r.genericParams:
      for name in g.names:
        if $name == key:
          g.typ = body[0][0]
    result.add body
  result.add r.NimNode

macro curlies(x: untyped{nkProcDef}): untyped =
  result = rewriteProc(routineNode(x))
  echo result.repr

when fromMacro:
  # proc nestedAddOne[T; U, V: int](_, _ = T{x: {y: ys, other}}, _ = T{other}, unused = ""): int {.curlies.} =
  # proc nestedAddOne[T, U](_ = T{x: {y: ys, other}}, _ = U{other: other2}, unused = ""): int {.curlies.} =
    # echo other
    # ys[0] + 1

  proc nestedAddTwo[T](_ = T{x: {y}}, unused = ""): int {.curlies.} =
    y + 2

  # proc nestedAddYs1[T](_: T{x: {y: ys}}, unused = ""): int {.curlies.} =
  #   y1 + y2

  # proc nestedAddYs2[T, U](_: T{x: {y: y1}}, _: U{x: {y: y2}}, unused = ""): int {.curlies.} =
  #   y1 + y2

else:
  type
    TheConcept = concept var theVar
      theVar.x.y
      theVar.x.other
  proc nestedAddTwo[T: TheConcept](a: T, unused = ""): int =
    let
      renamedY = a.x.y
      other = a.x.other
    echo other
    renamedY + 2

type
  X = object
    y: int
    other: string
  Obj1 = object
    x: X
    other: string
  Obj2 = object
    x: X

let o1 = Obj1(x: X(y: 3, other: "coucou1"))
let o2 = Obj2(x: X(y: 3, other: "coucou2"))
echo o1.nestedAddTwo
echo o2.nestedAddTwo
