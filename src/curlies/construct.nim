import std/[macros, strutils]
import curlies/[def, errors, fungus_utils]

proc construct*(T: NimNode, params: NimNode): tuple[obj, final: NimNode, dotdotId: string] =
  var def = getDef T
  if def.quality.len > 2:
    error("Unsupported type: $1 is $2" % [$T, $def.quality])
  elif def.isAdtChild():
    def.quality = @[Tuple]
  result.obj = nnkObjConstr.newTree(def.sym)
  result.dotdotId = ""
  for param in params:
    case param.kind
    of nnkIdent:
      result.obj.add nnkExprColonExpr.newTree(param, param)
    of nnkExprColonExpr:
      result.obj.add param
    # of nnkExprEqExpr:  # support `{x = ...}` syntax ?
    #   let colonExpr = nnkExprColonExpr.newTree()
    #   param.copyChildrenTo(colonExpr)
    #   result.add colonExpr
    elif param.kind == nnkPrefix and param[0] == ident"..":
      result.dotdotId = registerNode(param[1])
    else:
      error("Unexpected " & $param.kind & ": " & param.repr, param)
  result.final = result.obj
  case def.quality[0]
  of Object:
    discard
  of Ref, Generic:
    result.final[0] = T
  of Distinct:
    result.final = newCall(T, result.final)
  of Tuple:
    let tup = nnkTupleConstr.newTree()
    for param in result.obj[1..^1]:
      tup.add param
    result.obj = tup
    result.final = tup
