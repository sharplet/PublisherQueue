import Combine

public struct QueuedPublisher<Base: Publisher>: Publisher {
  public typealias Output = Base.Output
  public typealias Failure = Base.Failure

  let publisher: Base
  let queue: PublisherQueue

  public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
    let subscription = Subscription(
      subscriber: subscriber,
      queuedPublisher: queue._enqueue(publisher)
    )
    subscriber.receive(subscription: subscription)
  }
}

private extension QueuedPublisher {
  final class Subscription<S: Subscriber> where S.Input == Output, S.Failure == Failure {
    private let downstream: S
    private var upstream: Combine.Subscription!

    init(subscriber: S, queuedPublisher: AnyPublisher<AnyEvent, Never>) {
      self.downstream = subscriber
      queuedPublisher.subscribe(self) // sets self.upstream
    }
  }
}

extension QueuedPublisher.Subscription: Subscription {
  func request(_ demand: Subscribers.Demand) {
    upstream.request(demand)
  }

  func cancel() {
    upstream.cancel()
    upstream = nil
  }
}

extension QueuedPublisher.Subscription: Subscriber {
  func receive(subscription: Subscription) {
    upstream = subscription
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
    upstream = nil
  }
}
