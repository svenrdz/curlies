import std/macros
import curlies/errors

proc construct*(T: NimNode, params: NimNode): tuple[obj: NimNode, dotdotId: string] =
  result.obj = nnkObjConstr.newTree(T)
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
