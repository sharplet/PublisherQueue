import Combine
import PublisherQueue
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var subscriptions = Set<AnyCancellable>()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let total = 1000
    let group = DispatchGroup()
    let queue = PublisherQueue(size: total)

    var count = 0

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

