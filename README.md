# PublisherQueue

**Note:** This is a proof of concept that hasn't been tested in production. The
core functionality should be sound, but the code is primarily being published
as a reference and likely will not be maintained. Use at your own discretion!

-----

`PublisherQueue` is a class that manages the serial or concurrent execution of
Combine publishers. It can be used to serialise asynchronous tasks larger than
a single closure, or to place an upper bound on concurrency between publishers
(by customising the `maxConcurrentPublishers` argument).

For example, if not for the maximum of 1 concurrent publisher, the following
code would exhibit a data race on the `count` variable, and the count would be
unlikely to match the expected total.

```swift
let total = 1000
let group = DispatchGroup()
let queue = PublisherQueue(size: total) // maxConcurrentPublishers = .max(1)

var count = 0
var subscriptions = Set<AnyCancellable>()

for i in 0 ..< total {
  let publisher = Just(i)
    .subscribe(on: DispatchQueue.global())
    .enqueue(on: queue)

  group.enter()
  publisher.sink { _ in
    count += 1
    group.leave()
  }.store(in: &subscriptions)
}

group.wait()
print("Expected: \(total), received: \(count)")
// Expected: 1000, received: 1000
```

## License

PublisherQueue is Copyright © 2020 Adam Sharp. It is free software, and
may be redistributed under the terms specified in the [LICENSE][] file.

  [LICENSE]: /LICENSE
