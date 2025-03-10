// A module with library evolution enabled has two different "minimum versions".
// One, the minimum deployment target, is the lowest version that non-ABI
// declarations and bodies of non-inlinable functions will ever see. The other,
// the minimum inlining target, is the lowest version that ABI declarations and
// inlinable bodies will ever see.
//
// Test that we use the right version floor in the right places.
//
// To keep this test multi-platform, we only check fragments of diagnostics that
// don't include platform names or versions.

// REQUIRES: swift_stable_abi


// Primary execution of this test. Uses the default minimum inlining version,
// which is the version when the ABI became stable.
// RUN: %target-typecheck-verify-swift -swift-version 5 -enable-library-evolution -target %target-next-stable-abi-triple -target-min-inlining-version abi


// Check that these rules are only applied when requested and that at least some
// diagnostics are not present without it.
// RUN: not %target-typecheck-verify-swift -swift-version 5 -target %target-next-stable-abi-triple 2>&1 | %FileCheck --check-prefix NON_ABI %s
// NON_ABI: error: expected error not produced
// NON_ABI: {'BetweenTargets' is only available in}


// Check that we respect -target-min-inlining-version by cranking it up high
// enough to suppress any possible errors.
// RUN: %target-swift-frontend -typecheck -disable-objc-attr-requires-foundation-module %s -swift-version 5 -enable-library-evolution -target %target-next-stable-abi-triple -target-min-inlining-version 42.0

/// Declaration with no availability annotation. Should be inferred as minimum
/// inlining target.
public struct NoAvailable {
  @usableFromInline internal init() {}
}

@available(macOS 10.14.3, iOS 12.1, tvOS 12.1, watchOS 5.1, *)
public struct BeforeInliningTarget {
  @usableFromInline internal init() {}
}

@available(macOS 10.14.4, iOS 12.2, tvOS 12.2, watchOS 5.2, *)
public struct AtInliningTarget {
  @usableFromInline internal init() {}
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
public struct BetweenTargets {
  @usableFromInline internal init() {}
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public struct AtDeploymentTarget {
  @usableFromInline internal init() {}
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public struct AfterDeploymentTarget {
  @usableFromInline internal init() {}
}



//
// Uses in resilient functions are based on the minimum deployment target
// (i.e. the -target).
//

public func deployedUseNoAvailable( // expected-note 5 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.3, iOS 12.1, tvOS 12.1, watchOS 5.1, *)
public func deployedUseBeforeInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.4, iOS 12.2, tvOS 12.2, watchOS 5.2, *)
public func deployedUseAtInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
public func deployedUseBetweenTargets(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
public func deployedUseAtDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
public func deployedUseAfterDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget()
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget()
}



//
// Uses in inlinable functions are based on the minimum inlining target
// (i.e. the first ABI-stable version, in this case)
//

@inlinable public func inlinedUseNoAvailable( // expected-note 8 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.3, iOS 12.1, tvOS 12.1, watchOS 5.1, *)
@inlinable public func inlinedUseBeforeInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} {{18-25=10.14.5}} || {{31-35=12.3}} || {{42-46=12.3}} || {{56-59=5.3}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.4, iOS 12.2, tvOS 12.2, watchOS 5.2, *)
@inlinable public func inlinedUseAtInliningTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} {{18-25=10.14.5}} || {{31-35=12.3}} || {{42-46=12.3}} || {{56-59=5.3}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
@inlinable public func inlinedUseBetweenTargets(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
@inlinable public func inlinedUseAtDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

@available(macOS 11, iOS 14, tvOS 14, watchOS 7, *)
@inlinable public func inlinedUseAfterDeploymentTarget(
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets,
  _: AtDeploymentTarget,
  _: AfterDeploymentTarget
) {
  defer {
    _ = AtDeploymentTarget()
    _ = AfterDeploymentTarget()
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets()
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget()
}

//
// Edge cases.
//

// Internal functions should use the minimum deployment target.

internal func fn() {
  _ = AtDeploymentTarget()
}

// @_alwaysEmitIntoClient acts like @inlinable.

@_alwaysEmitIntoClient public func aEICUseNoAvailable( // expected-note 8 {{add @available attribute}}
  _: NoAvailable,
  _: BeforeInliningTarget,
  _: AtInliningTarget,
  _: BetweenTargets, // expected-error {{'BetweenTargets' is only available in}}
  _: AtDeploymentTarget, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
) {
  defer {
    _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  }
  _ = NoAvailable()
  _ = BeforeInliningTarget()
  _ = AtInliningTarget()
  _ = BetweenTargets() // expected-error {{'BetweenTargets' is only available in}} expected-note {{add 'if #available'}}
  _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

  if #available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *) {
    _ = BetweenTargets()
  }
  if #available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *) {
    _ = AtDeploymentTarget()
  }
  if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
    _ = AfterDeploymentTarget()
  }
}

// Default arguments act like @inlinable.

public func defaultArgsUseNoAvailable( // expected-note 3 {{add @available attribute}}
  _: Any = NoAvailable.self,
  _: Any = BeforeInliningTarget.self,
  _: Any = AtInliningTarget.self,
  _: Any = BetweenTargets.self, // expected-error {{'BetweenTargets' is only available in}}
  _: Any = AtDeploymentTarget.self, // expected-error {{'AtDeploymentTarget' is only available in}}
  _: Any = AfterDeploymentTarget.self // expected-error {{'AfterDeploymentTarget' is only available in}}
) {}

public struct PublicStruct { // expected-note 7 {{add @available attribute}}
  // Public declarations act like @inlinable.
  public var aPublic: NoAvailable
  public var bPublic: BeforeInliningTarget
  public var cPublic: AtInliningTarget
  public var dPublic: BetweenTargets // expected-error {{'BetweenTargets' is only available in}}
  public var ePublic: AtDeploymentTarget // expected-error {{'AtDeploymentTarget' is only available in}}
  public var fPublic: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  // Internal declarations act like non-inlinable.
  var aInternal: NoAvailable
  var bInternal: BeforeInliningTarget
  var cInternal: AtInliningTarget
  var dInternal: BetweenTargets
  var eInternal: AtDeploymentTarget
  var fInternal: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  @available(macOS 10.14.5, iOS 12.3, tvOS 12.3, watchOS 5.3, *)
  public internal(set) var internalSetter: Void {
    @inlinable get {
      // Public inlinable getter acts like @inlinable
      _ = NoAvailable()
      _ = BeforeInliningTarget()
      _ = AtInliningTarget()
      _ = BetweenTargets()
      _ = AtDeploymentTarget() // expected-error {{'AtDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
      _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

    }
    set {
      // Private setter acts like non-inlinable
      _ = NoAvailable()
      _ = BeforeInliningTarget()
      _ = AtInliningTarget()
      _ = BetweenTargets()
      _ = AtDeploymentTarget()
      _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
    }
  }
}

@frozen public struct FrozenPublicStruct { // expected-note 6 {{add @available attribute}}
  // Public declarations act like @inlinable.
  public var aPublic: NoAvailable
  public var bPublic: BeforeInliningTarget
  public var cPublic: AtInliningTarget
  public var dPublic: BetweenTargets // expected-error {{'BetweenTargets' is only available in}}
  public var ePublic: AtDeploymentTarget // expected-error {{'AtDeploymentTarget' is only available in}}
  public var fPublic: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}

  // Internal declarations act like @inlinable in a frozen struct.
  var aInternal: NoAvailable
  var bInternal: BeforeInliningTarget
  var cInternal: AtInliningTarget
  var dInternal: BetweenTargets // expected-error {{'BetweenTargets' is only available in}}
  var eInternal: AtDeploymentTarget // expected-error {{'AtDeploymentTarget' is only available in}}
  var fInternal: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
}

internal struct InternalStruct { // expected-note {{add @available attribute}}
  // Internal declarations act like non-inlinable.
  var aInternal: NoAvailable
  var bInternal: BeforeInliningTarget
  var cInternal: AtInliningTarget
  var dInternal: BetweenTargets
  var eInternal: AtDeploymentTarget
  var fInternal: AfterDeploymentTarget // expected-error {{'AfterDeploymentTarget' is only available in}}
}

// Top-level code, if somehow present in a resilient module, is treated like
// a non-inlinable function.
defer {
  _ = AtDeploymentTarget()
  _ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}
}
_ = NoAvailable()
_ = BeforeInliningTarget()
_ = AtInliningTarget()
_ = BetweenTargets()
_ = AtDeploymentTarget()
_ = AfterDeploymentTarget() // expected-error {{'AfterDeploymentTarget' is only available in}} expected-note {{add 'if #available'}}

if #available(macOS 11, iOS 14, tvOS 14, watchOS 7, *) {
  _ = AfterDeploymentTarget()
}

