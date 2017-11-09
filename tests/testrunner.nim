import macros ,interfacen

type
  Cup = object of RootObj
    weight: float

  CoffeeCup = object of Cup

  BigCoffeeMug = object of CoffeeCup

  TeaCup = object of Cup

#type  WaterResistant = concept this
Interface WaterResistant:
#  this.resistsFor() is float
  proc resistsFor(w: WaterResistant): float

#type Washable = concept this of WaterResistant
Interface Washable of WaterResistant:
#  this.wash() is bool
  proc wash(w: Washable): bool

proc resistsFor(c: Cup): float =
  result = 2435.6

proc wash(c: Cup): bool =
  result = true
  echo "Washing a Cup."
#[
]#

proc wash(c: CoffeeCup): bool =
  result = true
  echo "Washing a CoffeeCup."

implements WaterResistant, Washable: Cup

proc keepClean(w: Washable) =
  discard w.wash()

let
  c = Cup()
  cc = CoffeeCup()

keepClean(c)
keepClean(cc)
