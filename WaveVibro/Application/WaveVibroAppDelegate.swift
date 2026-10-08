import UIKit

final class WaveVibroAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        AnalyticsService.shared.configure()
        AttributionService.shared.configure(launchOptions: launchOptions)
        AnalyticsService.shared.track("App Launched")
        return true
    }
}
