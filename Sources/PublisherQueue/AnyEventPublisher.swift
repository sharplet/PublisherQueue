import Combine

enum AnyEvent {
  case output(Any)
  case completion(Subscribers.Completion<Error>)
}

extension Publisher {
  func eraseToAnyEventPublisher() -> AnyPublisher<AnyEvent, Never> {
    map(AnyEvent.output)
      .append(AnyEvent.completion(.finished))
      .catch { error in Just(.completion(.failure(error))) }
      .eraseToAnyPublisher()
  }
}
