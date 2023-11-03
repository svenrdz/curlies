type
  Person* = object
    name*: string
    age: int
    favouriteNumber*: int = 3
  User* = object
    name*, email*: string
  AccountKind* = enum
    Free, Paid
  Account* = object
    name*, email*: string
    case kind*: AccountKind
    of Free:
      nbRequests*: int
    of Paid:
      remainingDays*: int = 31
      someOtherField*: int
      unexportedField: float
