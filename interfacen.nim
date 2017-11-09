#[
   Explicit and implicit Interfaces.
   
   Copyright 2017 Gerd Mathar

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]#

discard """
  Interfaces are implemented as dumbed-down concepts here. Their main purpose
  is giving people something familiar to work with where the full power of
  concepts is not necessary.
"""

## This module implements explicit (Java-like) and implicit (Go-like)
## interfaces. An explicit interface ``I`` needs an explicit ``implements``-
## relation to a type ``T`` for ``T is I`` to be true. The implicit variety
## only requires a type to satisfy its interface description.
##
## Use
## ===
##
## .. code-block:: nim
##   Interface Friend:
##     type 
##       BeerSupply = enum
##         none, some, loads, allOfIt
##
##     const beerInFridge = some
##
##     proc willHelpMoving(f: Friend, hours: float): bool
##
##     proc greet(f: Friend): string =
##       echo "Howdy"
## Defines an explicit interface ``Friend`` with two procedures. The first
## argument must always be of the type of the interface itself. The second
## procedure has a default implementation which will be used if none is defined
## for an implementing type. The type and constant defined here are accessible
## from the implementations of the declared procedures.
##
## .. code-block:: nim
##   Interface Buddy of Friend:
##     proc willHelpMoving(f: Friend, hours: float): bool =
##      result = true
## Derives a new interface ``Buddy`` from an existing one, ``Friend``.
##
## .. code-block:: nim
##   implicit Interface Fringe:
##     proc knows(p: Fringe, f: Friend): bool
## Defines an implicit interface.
##
## .. code-block:: nim
##   implements Friend, Fringe: Selma
## Defines ``implements``-relations for an existing type and existing interfaces:
## ``Selma`` implements interfaces ``Friend`` and ``Fringe``.
##
## .. code-block:: nim
##   implements ExI:
##     type
##       Xx = object
##         x: float
##   
##       Y = object
##         x: float
##
##   type
##     Y2 = object
##       x: float
##
##   echo(Y is ExI)   # -> true
##   echo(Y2 is ExI)  # -> false
## Defines ``implements``-relations for new types: ``Xx`` and ``Y``
## implement interface ``ExI``. Note that, despite the fact that it fulfills
## the requirement in the body of ``ExI``, ``Y2`` does not satisfy ``ExD``
## because ``ExI`` is explicit and there is no ``implements``-relation
## defined between the two. 

import explicitconcepts as ec, macros, strutils
export ec.implements, ec.explicit

const
  concVarName = "this"

proc err(n: NimNode, msg: string = "syntax error.") =
  error(msg, n)

proc nameInfo(n: NimNode): tuple[name: NimNode, exp: bool] =
  var
    name: NimNode
    op: string

  case n.kind
  of nnkIdent:
    result = (n, false)
  of nnkPrefix:
    (name, op) = unpackPrefix n
    if "*" != op:
      err(n[0])
    result = (name, true)
  else: err(n)

proc transformDef(def: NimNode): NimNode =
  var
    name = def[0]
    params = def[3]
    resultType = params[0]
    paramTypes: seq[NimNode] = @[]

  for i in 2..params.len-1:
    let param = params[i]
    param.expectKind nnkIdentDefs
    paramTypes.add param[1]

  result = newTree(nnkInfix,
    newIdentNode "is",
    newCall(
      newTree(nnkDotExpr,
        newIdentNode(concVarName),
        name
      ),
      paramTypes
    ),
    resultType
  )

proc processBody(body: NimNode): tuple[body: NimNode, ext: seq[NimNode]] =
  result = (newStmtList(), @[])
  for stmt in body:
    if stmt.kind in {nnkProcDef, nnkMethodDef}:
      result.body.add stmt.transformDef
      if nnkStmtList == stmt.last.kind:
        result.ext.add stmt.copy
    else:
      result.body.add stmt.copy

proc ifaceInfo(args: NimNode): tuple[body: NimNode, ext: seq[NimNode]] =
  var
    fst, name, nameTree, fstBase, tBody: NimNode
    op: string
    exp: bool
    bases, baseRefs, ext: seq[NimNode] = @[]

  args.expectKind nnkArglist
  fst = args[0]
  if nnkInfix == fst.kind:
    (nameTree, op, fstBase) = unpackInfix fst
    if "of" != op:
      err(fst[0])
    (name, exp) = nameInfo nameTree
    bases.add fstBase
    if args.len > 2:
      for i in 1..args.len-2:
        bases.add args[i]
  else:
    (name, exp) = nameInfo fst
  if nnkStmtList != args.last.kind:
    err(fst, "body expected.")
  (tBody, ext) = processBody args.last

  # TODO: We need this because concept refinement doesn't work?!
  if bases.len > 0:
    for i in bases.len-1..0:
      tBody.insert(0, newTree(nnkInfix,
        newIdentNode("is"),
        newIdentNode(!concVarName),
        newIdentNode(bases[i].ident)
      ))

#  echo "$# $# $#" % [$name, $exp, $bases]

  result = (
    newTree(nnkTypeSection,
      newTree(nnkTypeDef,
        if exp:
          newTree(nnkPostfix, newIdentNode "*", name)
        else:
          name
        ,
        newEmptyNode(),
        newTree(nnkTypeClassTy,
          newTree(nnkArglist,
            newIdentNode concVarName
          ),
          newEmptyNode(),
          if bases.len > 0:
            newTree(nnkOfInherit, bases)
          else:
            newEmptyNode()
          ,
          tBody
        )
      )
    ),
    ext
  )

  echo "------- body:"
  echo result.body.treeRepr
  echo "------- ext:"
  for e in result.ext:
    echo e.treeRepr
#[
]#

macro Interface*(args: varargs[untyped]): untyped =
  let ii = ifaceInfo args
  result = newCall("explicit", newStmtList ii.body, newStmtList ii.ext)
 
macro ImplicitInterface*(args: varargs[untyped]): untyped =
  let ii = ifaceInfo args
  result = newStmtList(ii.body)
  for e in ii.ext:
    result.add e
