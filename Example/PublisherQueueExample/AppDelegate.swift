import Combine
import PublisherQueue
import UIKit

func randomInt() -> Deferred<Future<Int, Never>> {
  Deferred {
    Future { promise in
      DispatchQueue.global().asyncAfter(deadline: .now() + 0.001) {
        promise(.success(.random(in: .min ... .max)))
      }
    }
  }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var subscriptions = Set<AnyCancellable>()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let q = PublisherQueue(size: .max)
    var resultCount = 0
    let group = DispatchGroup()
    for _ in 1 ... 1000 {
      group.enter()
      q.queuedPublisher(randomInt()).sink(receiveCompletion: { _ in group.leave() }) { number in
        resultCount += 1
      }.store(in: &subscriptions)
    }
    group.wait()
    print(resultCount, "results")
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }


}

