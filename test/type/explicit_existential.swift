// RUN: %target-typecheck-verify-swift

protocol HasSelfRequirements {
  func foo(_ x: Self)

  func returnsOwnProtocol() -> any HasSelfRequirements
}
protocol Bar {
  init()

  func bar() -> any Bar
}

func useBarAsType(_ x: any Bar) {}

protocol Pub : Bar { }

func refinementErasure(_ p: any Pub) {
  useBarAsType(p)
}

typealias Compo = HasSelfRequirements & Bar

struct CompoAssocType {
  typealias Compo = HasSelfRequirements & Bar
}

func useAsRequirement<T: HasSelfRequirements>(_ x: T) { }
func useCompoAsRequirement<T: HasSelfRequirements & Bar>(_ x: T) { }
func useCompoAliasAsRequirement<T: Compo>(_ x: T) { }
func useNestedCompoAliasAsRequirement<T: CompoAssocType.Compo>(_ x: T) { }

func useAsWhereRequirement<T>(_ x: T) where T: HasSelfRequirements {}
func useCompoAsWhereRequirement<T>(_ x: T) where T: HasSelfRequirements & Bar {}
func useCompoAliasAsWhereRequirement<T>(_ x: T) where T: Compo {}
func useNestedCompoAliasAsWhereRequirement<T>(_ x: T) where T: CompoAssocType.Compo {}

func useAsType(_: any HasSelfRequirements,
               _: any HasSelfRequirements & Bar,
               _: any Compo,
               _: any CompoAssocType.Compo) { }

struct TypeRequirement<T: HasSelfRequirements> {}
struct CompoTypeRequirement<T: HasSelfRequirements & Bar> {}
struct CompoAliasTypeRequirement<T: Compo> {}
struct NestedCompoAliasTypeRequirement<T: CompoAssocType.Compo> {}

struct CompoTypeWhereRequirement<T> where T: HasSelfRequirements & Bar {}
struct CompoAliasTypeWhereRequirement<T> where T: Compo {}
struct NestedCompoAliasTypeWhereRequirement<T> where T: CompoAssocType.Compo {}

struct Struct1<T> { }

typealias T1 = Pub & Bar
typealias T2 = any Pub & Bar

protocol HasAssoc {
  associatedtype Assoc
  func foo()
}

do {
  enum MyError: Error {
    case bad(Any)
  }

  func checkIt(_ js: Any) throws {
    switch js {
    case let dbl as any HasAssoc:
      throw MyError.bad(dbl)

    default:
      fatalError("wrong")
    }
  }
}

func testHasAssoc(_ x: Any, _: any HasAssoc) {
  if let p = x as? any HasAssoc {
    p.foo()
  }

  struct ConformingType : HasAssoc {
    typealias Assoc = Int
    func foo() {}

    func method() -> any HasAssoc {}
  }
}

var b: any HasAssoc

protocol P {}
typealias MoreHasAssoc = HasAssoc & P
func testHasMoreAssoc(_ x: Any) {
  if let p = x as? any MoreHasAssoc {
    p.foo()
  }
}

typealias X = Struct1<any Pub & Bar>
_ = Struct1<any Pub & Bar>.self

typealias AliasWhere<T> = T
where T: HasAssoc, T.Assoc == any HasAssoc

struct StructWhere<T>
where T: HasAssoc,
      T.Assoc == any HasAssoc {}

protocol ProtocolWhere where T == any HasAssoc {
  associatedtype T

  associatedtype U: HasAssoc
    where U.Assoc == any HasAssoc
}

extension HasAssoc where Assoc == any HasAssoc {}

func FunctionWhere<T>(_: T)
where T : HasAssoc,
      T.Assoc == any HasAssoc {}

struct SubscriptWhere {
  subscript<T>(_: T) -> Int
  where T : HasAssoc,
        T.Assoc == any HasAssoc {
    get {}
    set {}
  }
}

struct OuterGeneric<T> {
  func contextuallyGenericMethod() where T == any HasAssoc {}
}

func testInvalidAny() {
  struct S: HasAssoc {
    typealias Assoc = Int
    func foo() {}
  }
  let _: any S = S() // expected-error{{'any' has no effect on concrete type 'S'}}

  func generic<T: HasAssoc>(t: T) {
    let _: any T = t // expected-error{{'any' has no effect on type parameter 'T'}}
    let _: any T.Assoc // expected-error {{'any' has no effect on type parameter 'T.Assoc'}}
  }

  let _: any ((S) -> Void) = generic // expected-error{{'any' has no effect on concrete type '(S) -> Void'}}
}

func anyAny() {
  let _: any Any
  let _: any AnyObject
}

protocol P1 {}
protocol P2 {}
do {
  // Test that we don't accidentally misparse an 'any' type as a 'some' type
  // and vice versa.
  let _: P1 & any P2 // expected-error {{'any' should appear at the beginning of a composition}}
  let _: any P1 & any P2 // expected-error {{'any' should appear at the beginning of a composition}}
  let _: any P1 & some P2 // expected-error {{'some' should appear at the beginning of a composition}}
  let _: some P1 & any P2
  // expected-error@-1 {{'some' type can only be declared on a single property declaration}}
  // expected-error@-2 {{'any' should appear at the beginning of a composition}}
}

struct ConcreteComposition: P1, P2 {}

func testMetatypes() {
  let _: any P1.Type = ConcreteComposition.self
  let _: any (P1 & P2).Type = ConcreteComposition.self
}

func generic<T: any P1>(_ t: T) {} // expected-error {{type 'T' constrained to non-protocol, non-class type 'any P1'}}

protocol RawRepresentable {
  associatedtype RawValue
  var rawValue: RawValue { get }
}

enum E1: RawRepresentable {
  typealias RawValue = P1

  var rawValue: P1 {
    return ConcreteComposition()
  }
}

enum E2: RawRepresentable {
  typealias RawValue = any P1

  var rawValue: any P1 {
    return ConcreteComposition()
  }
}

public protocol MyError {}

extension MyError {
  static func ~=(lhs: any Error, rhs: Self) -> Bool {
    return true
  }
}

struct Wrapper {
  typealias E = Error
}

func typealiasMemberReferences(metatype: Wrapper.Type) {
  let _: Wrapper.E.Protocol = metatype.E.self
  let _: (any Wrapper.E).Type = metatype.E.self
}

func testAnyTypeExpr() {
  let _: (any P).Type = (any P).self

  func test(_: (any P).Type) {}
  test((any P).self)

  // expected-error@+2 {{expected member name or constructor call after type name}}
  // expected-note@+1 {{use '.self' to reference the type object}}
  let invalid = any P
  test(invalid)

  // Make sure 'any' followed by an identifier
  // on the next line isn't parsed as a type.
  func doSomething() {}

  let any = 10
  let _ = any
  doSomething()
}

func hasInvalidExistential(_: any DoesNotExistIHope) {}
// expected-error@-1 {{cannot find type 'DoesNotExistIHope' in scope}}

protocol Input {
  associatedtype A
}
protocol Output {
  associatedtype A
}

// expected-warning@+2{{protocol 'Input' as a type must be explicitly marked as 'any'}}{{30-35=any Input}}
// expected-warning@+1{{protocol 'Output' as a type must be explicitly marked as 'any'}}{{40-46=any Output}}
typealias InvalidFunction = (Input) -> Output
func testInvalidFunctionAlias(fn: InvalidFunction) {}

typealias ExistentialFunction = (any Input) -> any Output
func testFunctionAlias(fn: ExistentialFunction) {}

typealias Constraint = Input
func testConstraintAlias(x: Constraint) {} // expected-warning{{'Constraint' (aka 'Input') as a type must be explicitly marked as 'any'}}{{29-39=any Constraint}}

typealias Existential = any Input
func testExistentialAlias(x: Existential, y: any Constraint) {}

// Reject explicit existential types in inheritance clauses
protocol Empty {}

struct S : any Empty {} // expected-error {{inheritance from non-protocol type 'any Empty'}}
class C : any Empty {} // expected-error {{inheritance from non-protocol, non-class type 'any Empty'}}

// FIXME: Diagnostics are not great in the enum case because we confuse this with a raw type

enum E : any Empty { // expected-error {{raw type 'any Empty' is not expressible by a string, integer, or floating-point literal}}
// expected-error@-1 {{'E' declares raw type 'any Empty', but does not conform to RawRepresentable and conformance could not be synthesized}}
// expected-error@-2 {{RawRepresentable conformance cannot be synthesized because raw type 'any Empty' is not Equatable}}
  case hack
}

enum EE : Equatable, any Empty { // expected-error {{raw type 'any Empty' is not expressible by a string, integer, or floating-point literal}}
// expected-error@-1 {{'EE' declares raw type 'any Empty', but does not conform to RawRepresentable and conformance could not be synthesized}}
// expected-error@-2 {{RawRepresentable conformance cannot be synthesized because raw type 'any Empty' is not Equatable}}
// expected-error@-3 {{raw type 'any Empty' must appear first in the enum inheritance clause}}
  case hack
}

func testAnyFixIt() {
  struct ConformingType : HasAssoc {
    typealias Assoc = Int
    func foo() {}

    func method() -> any HasAssoc {}
  }

  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-18=any HasAssoc}}
  let _: HasAssoc = ConformingType()
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{19-27=any HasAssoc}}
  let _: Optional<HasAssoc> = nil
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-23=any HasAssoc.Type}}
  let _: HasAssoc.Type = ConformingType.self
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-25=any (HasAssoc).Type}}
  let _: (HasAssoc).Type = ConformingType.self
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-27=any ((HasAssoc)).Type}}
  let _: ((HasAssoc)).Type = ConformingType.self
  // expected-warning@+2 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-18=(any HasAssoc)}}
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{30-38=(any HasAssoc)}}
  let _: HasAssoc.Protocol = HasAssoc.self
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{11-19=any HasAssoc}}
  let _: (HasAssoc).Protocol = (any HasAssoc).self
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-18=(any HasAssoc)}}
  let _: HasAssoc? = ConformingType()
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-23=(any HasAssoc.Type)}}
  let _: HasAssoc.Type? = ConformingType.self
  // expected-warning@+1 {{'HasAssoc' as a type must be explicitly marked as 'any'}}{{10-18=(any HasAssoc)}}
  let _: HasAssoc.Protocol? = (any HasAssoc).self
}
