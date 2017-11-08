import interfacen, macros

type
  Selma = object
    n: int

#[
dumpTree:
  explicit do:
    type C = concept this
      this.willHelpMoving(float) is bool
  do:
    proc willHelpMoving(float): bool
]#

Interface *Friend:
  type 
    BeerSupply = enum
      none, some, loads, allOfIt
  const beerInFridge = some
  proc willHelpMoving(f: Friend, hours: float): bool
  proc greet(f: Friend): string =
    echo "Howdy"

Interface *Buddy of Friend:
  method willHelpMoving(f: Friend, hours: float): bool =
    result = true

ImplicitInterface Fringe:
  proc knows(p: Fringe, f: Friend): bool

implements Friend, Fringe: Selma
