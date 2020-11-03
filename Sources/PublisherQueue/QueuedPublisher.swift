import Combine
import os.lock

public struct QueuedPublisher<Base: Publisher>: Publisher {
  public typealias Output = Base.Output
  public typealias Failure = Base.Failure

  let publisher: Base
  let queue: PublisherQueue

  public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
    let operation = queue.makeOperation(publisher)
    let subscription = Subscription(
      subscriber: subscriber,
      queue: queue,
      operation: operation
    )
    subscriber.receive(subscription: subscription)
    queue.enqueue(operation)
  }
}

private extension QueuedPublisher {
  final class Subscription<S: Subscriber> where S.Input == Output, S.Failure == Failure {
    private let downstream: S
    private let lock: os_unfair_lock_t

    private var upstream: Combine.Subscription?

    init(subscriber: S, queue: PublisherQueue, operation: PublisherQueue.Operation) {
      self.downstream = subscriber
      self.lock = .allocate(capacity: 1)
      lock.initialize(to: os_unfair_lock())

      operation.readonly.subscribe(self) // sets self.upstream
    }

    deinit {
      lock.deinitialize(count: 1)
      lock.deallocate()
    }

    private func withLock<Result>(_ body: () throws -> Result) rethrows -> Result {
      os_unfair_lock_lock(lock)
      defer { os_unfair_lock_unlock(lock) }
      return try body()
    }
  }
}

extension QueuedPublisher.Subscription: Subscription {
  func request(_ demand: Subscribers.Demand) {
    let upstream = withLock { self.upstream }
    upstream?.request(demand)
  }

  func cancel() {
    let upstream = withLock { () -> Subscription? in
      defer { self.upstream = nil }
      return self.upstream
    }
    upstream?.cancel()
  }
}

extension QueuedPublisher.Subscription: Subscriber {
  func receive(subscription: Subscription) {
    withLock {
      upstream = subscription
    }
  }

  func receive(_ event: AnyEvent) -> Subscribers.Demand {
    switch event {
    case let .output(value):
      return downstream.receive(value as! Base.Output)

    case .completion(.finished):
      downstream.receive(completion: .finished)
      return .none

    case let .completion(.failure(error)):
      downstream.receive(completion: .failure(error as! Base.Failure))
      return .none
    }
  }

  func receive(completion _: Subscribers.Completion<Never>) {
    withLock {
      upstream = nil
    }
  }
}
