import std/[algorithm, genasts, macros, strutils]

import micros/[nimnames, nimnodes]
import micros/definitions/[identdefs, objectdefs]

import curlies/[field, utils, errors]

proc check(fields: seq[Field],
           rec: NimNode,
           originId: string,
           missing: var seq[NimName],
           exportedOnly: bool) =
  case rec.kind
  of nnkIdentDefs:
    let idef = IdentDef rec
    for name in idef.names:
      if not fields.has(name, idef.val):
        if (exportedOnly and name.isPostfixStar) or not exportedOnly:
          missing.add name.stripPostfix
  of nnkRecCase:
    let discriminator = IdentDef rec[0]
    if not fields.has(discriminator):
      if (exportedOnly and discriminator.name.isPostfixStar) or not exportedOnly:
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

proc addMissing(name: NimName, source: NimNode, sourceId: string): NimNode =
  let
    conds = fieldConditions(source, name)
    namenode = name.NimNode
    errorMsg = "missing field: $1" % $namenode
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
  result = colonExpr

proc removeMissingZeroDefault(obj: var NimNode,
                              fields: seq[Field],
                              missing: seq[NimName]) =
  var zerosIdx: seq[int]
  for i, field in fields:
    if field.isZeroDefault and field.name in missing:
      zerosIdx.add i + 1
  for idx in zerosIdx.reversed:
    obj.del idx

macro checkAndRewrite*(obj, final, dotdot: typed,
                       dotdotId, originId: static string): untyped =
  result = copyNimTree final
  let
    objSym = obj[1]
    fields = objSym.symFields
    def = objSym.objectDef
    origin = getNode(originId)
    exportedOnly = objSym.module != origin.module
  var missing: seq[NimName]
  for rec in def.recList:
    fields.check(rec, originId, missing, exportedOnly)
  for parent in def.inheritObjs:
    for rec in parent.recList:
      fields.check(rec, originId, missing, exportedOnly)
  if dotdotId.len > 0:
    result.removeMissingZeroDefault(fields, missing)
    for name in missing:
      result.add name.addMissing(dotdot, dotdotId)
  elif missing.len > 1:
    error($missing & ": initialization required.", origin)
  elif missing.len > 0:
    error($missing[0] & ": initialization required.", origin)
