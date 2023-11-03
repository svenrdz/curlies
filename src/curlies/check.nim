import std/[algorithm, genasts, macros, strutils]

import micros/[nimnames, nimnodes]
import micros/definitions/[identdefs, objectdefs]
import ast_pattern_matching

import curlies/[def, field, fungus_utils, utils, errors]

proc identDefsIsMissing(fields: seq[Field],
                    name: NimName,
                    defaultValue: NimNode,
                    exportedOnly: bool): bool =
  if not fields.has(name, defaultValue):
    if (exportedOnly and name.isPostfixStar) or not exportedOnly:
      result = true

proc checkObjectRec(fields: seq[Field], rec: NimNode, originId: string,
           missing: var seq[NimName], exportedOnly: bool) =
  case rec.kind
  of nnkIdentDefs:
    let idef = IdentDef rec
    for name in idef.names:
      if fields.identDefsIsMissing(name, idef.val, exportedOnly):
        missing.add name.stripPostfix
  of nnkRecCase:
    let discriminator = IdentDef rec[0]
    if fields.identDefsIsMissing(discriminator.name, discriminator.val, exportedOnly):
      missing.add discriminator.name.stripPostfix
    else:
      for field in fields:
        if field.isZeroDefault:
          if exportedOnly:
            for branch in rec[1..^1]:
              let branchRecList = branch[^1]
              for n in branchRecList:
                let
                  rawName = n[0]
                  name = rawName.stripPostfix
                  fieldName = field.name.NimNode.stripPostfix
                if name.eqIdent(fieldname) and rawName.isPostfixStar:
                  missing.add nimName(name)
          else:
            missing.add field.name.stripPostfix
  of nnkRecWhen:
    error("Curlies does not handle types that use `when`.", getNode(originId))
  else:
    error("Unexpected " & $rec.kind & ":\n" & rec.repr, getNode(originId))

proc errorMsg(name: NimName): string =
  "unreachable field: $1" % $name

proc addMissingObject(name: NimName, source: NimNode, sourceId: string): NimNode =
  let
    conds = fieldConditions(source, name)
    namenode = name.NimNode
    errorMsg = name.errorMsg
    infoObj = getNode(sourceId).lineInfoObj
    info = (infoObj.filename, infoObj.line)
    whenSource = genAst(source, namenode, errorMsg, sourceId, info, conds):
      when not compiles(source.namenode):
        errorNode(errorMsg, sourceId)
      if conds:
        source.namenode
      else:
        {.line: info.}:
          raise FieldDefect.newException(errorMsg)
        source.namenode
    colonExpr = nnkExprColonExpr.newTree(namenode, whenSource)
  colonExpr

proc addMissingDistinct(name: NimName, source: NimNode, sourceId: string): NimNode =
  let
    namenode = name.NimNode
    errorMsg = name.errorMsg
    whenSource = genAst(source, namenode, errorMsg, sourceId):
      when not compiles(source.namenode):
        errorNode(errorMsg, sourceId)
      else:
        source.namenode
    colonExpr = nnkExprColonExpr.newTree(namenode, whenSource)
  colonExpr

proc addMissingTuple(name: NimName, source: NimNode): NimNode =
  var constr = source.getImpl[2]
  if constr.kind == nnkConv:
    constr = constr[1]
  if constr.kind == nnkTupleConstr:
    for idef in constr:
      if idef[0].eqIdent(name.NimNode):
        let
          namenode = name.NimNode
          value = genAst(source, namenode):
            source.namenode
          colonExpr = nnkExprColonExpr.newTree(namenode, value)
        return colonExpr
    error("missing field $1" % [$name.NimNode], source)

proc addMissing(name: NimName, source: NimNode, sourceId: string): NimNode =
  case source.typeKind
  of ntyObject, ntyRef: # else ?
    return addMissingObject(name, source, sourceId)
  of ntyDistinct:
    return addMissingDistinct(name, source, sourceId)
  of ntyTuple:
    return addMissingTuple(name, source)
  else: discard

proc removeMissingZeroDefault(obj: var NimNode,
                              fields: seq[Field],
                              missing: seq[NimName]) =
  var zerosIdx: seq[int]
  for i, field in fields:
    if field.isZeroDefault and field.name in missing:
      zerosIdx.add i + 1
  for idx in zerosIdx.reversed:
    obj.del idx

proc checkAndRewriteObject(output: var NimNode,
                           fields: seq[Field],
                           def: DefObj,
                           originId, dotdotId: string,
                           dotdot: NimNode,
                           exportedOnly: bool): seq[NimName] =
  let
    isDistinct = def.quality[0] == Distinct
    def = def.obj.ObjectDef
    outputType = output[0]
  if isDistinct:
    output = output[1]
  for rec in def.recList:
    fields.checkObjectRec(rec, originId, result, exportedOnly)
  for parent in def.inheritObjs:
    for rec in parent.recList:
      fields.checkObjectRec(rec, originId, result, exportedOnly)
  if dotdotId.len > 0:
    output.removeMissingZeroDefault(fields, result)
    for name in result:
      output.add name.addMissing(dotdot, dotdotId)
    result = @[]
  if isDistinct:
    output = newCall(outputType, output)

proc checkAndRewriteTuple(output: var NimNode,
                          fields: seq[Field],
                          def: DefObj,
                          tupleTy: NimNode,
                          dotdotId: string,
                          dotdot: NimNode): seq[NimName] =
  for rec in tupleTy:
    let
      idef = IdentDef rec
    for name in idef.names:
      if fields.identDefsIsMissing(name, newEmptyNode(), exportedOnly = false):
        if idef.val.kind != nnkEmpty:
          matchAst(idef.NimNode):
          of nnkIdentDefs(_, nnkBracketExpr("seq", `typ`), `val` @ nnkBracket):
            ## upgrade array default values to seq with `@`
            let seqCast = newCall(nnkBracketExpr.newTree(ident"@", typ), val)
            output.add nnkExprColonExpr.newTree(name.NimNode, seqCast)
          else:
            output.add nnkExprColonExpr.newTree(name.NimNode, idef.val)
        elif dotdotId.len > 0:
          output.add name.addMissing(dotdot, dotdotId)
        else:
          result.add name.stripPostfix
      else:
        output.add nnkExprColonExpr.newTree(name.NimNode, fields[name])

proc checkAndRewriteFungus(output: var NimNode,
                           fields: seq[Field],
                           def: DefObj,
                           kind: NimNode,
                           dotdotId: string,
                           dotdot: NimNode): seq[NimName] =
  for branch in def.obj.objectDef.recList[0][1..^1]:
    if branch[0].eqIdent(kind):
      if branch[1].kind == nnkNilLit:
        break
      let
        valueName = branch[1][0]
        tupleTy = branch[1][1][0]
      var constr = nnkTupleConstr.newTree()
      result = constr.checkAndRewriteTuple(fields, def, tupleTy,
                                           dotdotId, dotdot)
      output.add nnkExprColonExpr.newTree(valueName, constr)
      break

macro checkAndRewrite*(obj, final, dotdot: typed,
                       dotdotId, originId: static string): untyped =
  let
    objSym = obj[1]
    fields = objSym.symFields
    origin = getNode(originId)
    exportedOnly = objSym.module != origin.module
    originDef = origin.getDef
  var missing: seq[NimName]
  if originDef.isAdtChild():
    let
      kind = ident($origin & "Kind")
      colonKind = nnkExprColonExpr.newTree(ident"kind", kind)
    result = nnkObjConstr.newTree(originDef.sym, colonKind)
    missing = result.checkAndRewriteFungus(fields, originDef, kind,
                                           dotdotId, dotdot)
    result = nnkCommand.newTree(origin, result)
  else:
    case originDef.quality[^1]:
      of Object:
        result = copyNimTree final
        missing = result.checkAndRewriteObject(fields, originDef, originId,
                                               dotdotId, dotdot, exportedOnly)
      of Tuple:
        result = nnkTupleConstr.newTree()
        let tupleTy = originDef.obj[^1]
        missing = result.checkAndRewriteTuple(fields, originDef, tupleTy,
                                              dotdotId, dotdot)
        result = nnkCommand.newTree(origin, result)
      else: error("impossible")
  if missing.len > 1:
    error($missing & ": initialization required.", origin)
  elif missing.len > 0:
    error($missing[0] & ": initialization required.", origin)
