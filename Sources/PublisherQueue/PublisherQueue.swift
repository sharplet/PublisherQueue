import Combine
import Dispatch

public final class PublisherQueue {
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

  func enqueue(_ operation: Operation) {
    operationQueue.send(operation)
  }

  func makeOperation<P: Publisher>(_ publisher: P) -> Operation {
    Operation(publisher: publisher)
  }
}

extension PublisherQueue {
  struct Operation {
    fileprivate typealias Publisher = Publishers.MakeConnectable<AnyPublisher<AnyEvent, Never>>

    private var publisher: Publisher

    fileprivate init<P: Combine.Publisher>(publisher: P) {
      self.publisher = publisher.eraseToAnyEventPublisher().makeConnectable()
    }

    var readonly: AnyPublisher<AnyEvent, Never> {
      publisher.eraseToAnyPublisher()
    }

    fileprivate func autoconnect() -> Publishers.Autoconnect<Publisher> {
      publisher.autoconnect()
    }
  }
}

extension Publisher {
  public func enqueue(on queue: PublisherQueue) -> QueuedPublisher<Self> {
    queue.queuedPublisher(self)
  }
}
