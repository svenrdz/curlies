import curlies
import ./check

type
  User = object
    name, email: string

  AccountKind = enum
    Free
    Paid

  Account = object
    name, email: string
    case kind: AccountKind
    of Free:
      nbRequests: int
    of Paid:
      remainingDays: int = 31
      someOtherField: int

const
  name = "user"
  email = "user@curli.es"
  user = User(name: name, email: email)

block:
  ## Update missing fields with `..` syntax into case objects, from regular
  ## objects. Target branch must be specified at compile-time.
  let
    freeUser1 = Account{kind: Free, nbRequests: 1000, ..user}
    freeUser2 = Account{name: "user2", kind: Free, ..freeUser1}
  check freeUser1.name != freeUser2.name
  check freeUser1.email == freeUser2.email
  check freeUser1.nbRequests == freeUser2.nbRequests
  expect FieldDefect:
    discard freeUser1.remainingDays
  expect FieldDefect:
    discard freeUser2.remainingDays

block:
  ## Update syntax with branch switching.
  ## If all branch-specific fields are known at compile-time or have
  ## default values, it's all good.
  let freeUser = Account{kind: Free, nbRequests: 1000, ..user}
  let paidUser = Account{kind: Paid, someOtherField: 4, ..freeUser}
  check freeUser.name == paidUser.name
  check freeUser.email == paidUser.email
  check freeUser.nbRequests == 1000
  check paidUser.remainingDays == 31
  expect FieldDefect:
    discard paidUser.nbRequests

block:
  ## Update syntax with branch switching.
  ## When some branch-specific fields are not known at compile-time, a
  ## runtime check happens at runtime, to know whether the fields can be
  ## accessed safely.
  ## Otherwise, a FieldDefect is raised.
  let freeUser = Account{kind: Free, nbRequests: 1000, ..user}
  expect FieldDefect:
    # TODO: add CT check to avoid FieldDefect?
    discard Account{kind: Paid, ..freeUser}

block:
  ## error on missing fields, even in case branches
  check not compiles(Account{})
  check not compiles(Account{..user})
  check not compiles(Account{kind: Free, ..user})
  check compiles(Account{kind: Free, nbRequests: 0, ..user})
