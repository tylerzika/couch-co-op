import UIKit
import SwiftUI
import MathLibSwift

@main
struct CoachCoOpApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize any required app setup
        print("tvOS App Delegate initialized")
        
        // Test the C library integration
        let result = MathLib.add(5, 3)
        print("Quick test: MathLib.add(5, 3) = \(result)")
        
        return true
    }
}
