import Combine
import Dispatch

public final class PublisherQueue {
  private typealias Operation = Publishers.MakeConnectable<AnyPublisher<AnyEvent, Never>>

  private let operationQueue: PassthroughSubject<Operation, Never>
  private var subscriptions: Set<AnyCancellable>

  public init(size: Int, maxConcurrentPublishers: Subscribers.Demand = .max(1)) {
    self.operationQueue = PassthroughSubject()
    self.subscriptions = []

    operationQueue
      .buffer(size: size, prefetch: .keepFull, whenFull: .dropNewest)
      .flatMap(maxPublishers: maxConcurrentPublishers) { operation in
        operation.autoconnect()
      }
      .sink { _ in }
      .store(in: &subscriptions)
  }

  public func queuedPublisher<P: Publisher>(_ publisher: P) -> QueuedPublisher<P> {
    QueuedPublisher(publisher: publisher, queue: self)
  }

  func _enqueue<P: Publisher>(_ publisher: P) -> AnyPublisher<AnyEvent, Never> {
    let operation = publisher.eraseToAnyEventPublisher().makeConnectable()
    operationQueue.send(operation)
    return operation.eraseToAnyPublisher()
  }
}
