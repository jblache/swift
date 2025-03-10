// RUN: %target-run-simple-swift(-Xfrontend -disable-availability-checking -Xfrontend -enable-experimental-distributed -parse-as-library) | %FileCheck %s

// REQUIRES: executable_test
// REQUIRES: concurrency
// REQUIRES: distributed

// rdar://76038845
// UNSUPPORTED: use_os_stdlib
// UNSUPPORTED: back_deployment_runtime

import _Distributed
import _Concurrency

struct Boom: Error {
  let whoFailed: String
  init(_ whoFailed: String) {
    self.whoFailed = whoFailed
  }
}

distributed actor SomeSpecificDistributedActor {
  let state: String = "hi there"

  distributed func helloAsyncThrows() async throws -> String {
    "local(\(#function))"
  }

  distributed func helloAsync() async -> String {
   "local(\(#function))"
  }

  distributed func helloThrows() throws -> String {
   "local(\(#function))"
  }

  distributed func hello() -> String {
   "local(\(#function))"
  }

  distributed func callTaskSelf_inner() async throws -> String {
    "local(\(#function))"
  }
  distributed func callTaskSelf() async -> String {
    do {
      return try await Task {
        let called = try await callTaskSelf_inner() // shouldn't use the distributed thunk!
        return "local(\(#function)) -> \(called)"
      }.value
    } catch {
      return "WRONG local(\(#function)) thrown(\(error))"
    }
  }

  distributed func callDetachedSelf() async -> String {
    do {
      return try await Task.detached {
        let called = try await self.callTaskSelf_inner() // shouldn't use the distributed thunk!
        return "local(\(#function)) -> \(called)"
      }.value
    } catch {
      return "WRONG local(\(#function)) thrown(\(error))"
    }
  }

  // === errors

  distributed func helloThrowsImplBoom() throws -> String {
    throw Boom("impl")
  }

  distributed func helloThrowsTransportBoom() throws -> String {
    "local(\(#function))"
  }
}

// ==== Execute ----------------------------------------------------------------

@_silgen_name("swift_distributed_actor_is_remote")
func __isRemoteActor(_ actor: AnyObject) -> Bool

func __isLocalActor(_ actor: AnyObject) -> Bool {
  return !__isRemoteActor(actor)
}

// ==== Fake Transport ---------------------------------------------------------

struct ActorAddress: Sendable, Hashable, Codable {
  let address: String
}

struct FakeActorSystem: DistributedActorSystem {
  typealias ActorID = ActorAddress
  typealias InvocationDecoder = FakeInvocationDecoder
  typealias InvocationEncoder = FakeInvocationEncoder
  typealias SerializationRequirement = Codable

  func resolve<Act>(id: ActorID, as actorType: Act.Type) throws -> Act?
      where Act: DistributedActor,
            Act.ID == ActorID {
    nil
  }

  func assignID<Act>(_ actorType: Act.Type) -> ActorID
      where Act: DistributedActor {
    ActorAddress(address: "")
  }

  func actorReady<Act>(_ actor: Act)
      where Act: DistributedActor,
      Act.ID == ActorID {
  }

  func resignID(_ id: ActorID) {
  }

  func makeInvocationEncoder() -> InvocationEncoder {
    .init()
  }

  public func remoteCall<Act, Err, Res>(
    on actor: Act,
    target: RemoteCallTarget,
    invocation invocationEncoder: inout InvocationEncoder,
    throwing: Err.Type,
    returning: Res.Type
  ) async throws -> Res
    where Act: DistributedActor,
          Act.ID == ActorID,
          Err: Error,
          Res: SerializationRequirement {
    guard target.mangledName != "$s4main28SomeSpecificDistributedActorC24helloThrowsTransportBoomSSyKFTE" else {
      throw Boom("system")
    }

    return "remote(\(target.mangledName))" as! Res
  }

  func remoteCallVoid<Act, Err>(
    on actor: Act,
    target: RemoteCallTarget,
    invocation invocationEncoder: inout InvocationEncoder,
    throwing: Err.Type
  ) async throws
    where Act: DistributedActor,
          Act.ID == ActorID,
          Err: Error {
    fatalError("not implemented: \(#function)")
  }
}

// === Sending / encoding -------------------------------------------------
struct FakeInvocationEncoder: DistributedTargetInvocationEncoder {
  typealias SerializationRequirement = Codable

  mutating func recordGenericSubstitution<T>(_ type: T.Type) throws {}
  mutating func recordArgument<Argument: SerializationRequirement>(_ argument: Argument) throws {}
  mutating func recordReturnType<R: SerializationRequirement>(_ type: R.Type) throws {}
  mutating func recordErrorType<E: Error>(_ type: E.Type) throws {}
  mutating func doneRecording() throws {}
}

// === Receiving / decoding -------------------------------------------------
class FakeInvocationDecoder : DistributedTargetInvocationDecoder {
  typealias SerializationRequirement = Codable

  func decodeGenericSubstitutions() throws -> [Any.Type] { [] }
  func decodeNextArgument<Argument: SerializationRequirement>() throws -> Argument { fatalError() }
  func decodeReturnType() throws -> Any.Type? { nil }
  func decodeErrorType() throws -> Any.Type? { nil }
}

@available(SwiftStdlib 5.5, *)
typealias DefaultDistributedActorSystem = FakeActorSystem

// ==== Execute ----------------------------------------------------------------

func test_remote_invoke(address: ActorAddress, system: FakeActorSystem) async {
  func check(actor: SomeSpecificDistributedActor) async {
    let personality = __isRemoteActor(actor) ? "remote" : "local"

    let h1 = try! await actor.helloAsyncThrows()
    print("\(personality) - helloAsyncThrows: \(h1)")

    let h2 = try! await actor.helloAsync()
    print("\(personality) - helloAsync: \(h2)")

    let h3 = try! await actor.helloThrows()
    print("\(personality) - helloThrows: \(h3)")

    let h4 = try! await actor.hello()
    print("\(personality) - hello: \(h4)")

    let h5 = try! await actor.callTaskSelf()
    print("\(personality) - callTaskSelf: \(h5)")

    let h6 = try! await actor.callDetachedSelf()
    print("\(personality) - callDetachedSelf: \(h6)")

    // error throws
    if __isRemoteActor(actor) {
      do {
        let h7 = try await actor.helloThrowsTransportBoom()
        print("WRONG: helloThrowsTransportBoom: should have thrown; got: \(h7)")
      } catch {
        print("\(personality) - helloThrowsTransportBoom: \(error)")
      }
    } else {
      do {
        let h8 = try await actor.helloThrowsImplBoom()
        print("WRONG: helloThrowsImplBoom: Should have thrown; got: \(h8)")
      } catch {
        print("\(personality) - helloThrowsImplBoom: \(error)")
      }
    }
  }

  let remote = try! SomeSpecificDistributedActor.resolve(id: address, using: system)
  assert(__isRemoteActor(remote) == true, "should be remote")

  let local = SomeSpecificDistributedActor(system: system)
  assert(__isRemoteActor(local) == false, "should be local")

  print("local isRemote: \(__isRemoteActor(local))")
  // CHECK: local isRemote: false
  await check(actor: local)
  // CHECK: local - helloAsyncThrows: local(helloAsyncThrows())
  // CHECK: local - helloAsync: local(helloAsync())
  // CHECK: local - helloThrows: local(helloThrows())
  // CHECK: local - hello: local(hello())
  // CHECK: local - callTaskSelf: local(callTaskSelf()) -> local(callTaskSelf_inner())
  // CHECK: local - callDetachedSelf: local(callDetachedSelf()) -> local(callTaskSelf_inner())
  // CHECK: local - helloThrowsImplBoom: Boom(whoFailed: "impl")

  print("remote isRemote: \(__isRemoteActor(remote))")
  // CHECK: remote isRemote: true
  await check(actor: remote)
  // TODO(distributed): remote - helloAsyncThrows: remote(_remote_impl_helloAsyncThrows())
  // CHECK: remote - helloAsyncThrows: remote($s4main28SomeSpecificDistributedActorC16helloAsyncThrowsSSyYaKFTE)
  // TODO(distributed): remote - helloAsync: remote()
  // CHECK: remote - helloAsync: remote($s4main28SomeSpecificDistributedActorC10helloAsyncSSyYaFTE)
  // TODO(distributed): remote - helloThrows: remote(_remote_impl_helloThrows())
  // CHECK: remote - helloThrows: remote($s4main28SomeSpecificDistributedActorC11helloThrowsSSyKFTE)
  // TODO(distributed): remote - hello: remote(_remote_impl_hello())
  // CHECK: remote - hello: remote($s4main28SomeSpecificDistributedActorC5helloSSyFTE)
  // TODO(distributed): remote - callTaskSelf: remote(_remote_impl_callTaskSelf())
  // CHECK: remote - callTaskSelf: remote($s4main28SomeSpecificDistributedActorC12callTaskSelfSSyYaFTE)
  // TODO(distributed): remote - callDetachedSelf: remote(_remote_impl_callDetachedSelf())
  // CHECK: remote - callDetachedSelf: remote($s4main28SomeSpecificDistributedActorC16callDetachedSelfSSyYaFTE)
  // CHECK: remote - helloThrowsTransportBoom: Boom(whoFailed: "system")

  print(local)
  print(remote)
}

@main struct Main {
  static func main() async {
    let address = ActorAddress(address: "")
    let system = DefaultDistributedActorSystem()

    await test_remote_invoke(address: address, system: system)
  }
}
