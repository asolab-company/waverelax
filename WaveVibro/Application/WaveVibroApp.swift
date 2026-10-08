import SwiftUI

@main
struct WaveVibroApp: App {
    @UIApplicationDelegateAdaptor(WaveVibroAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .environment(environment)
                .onChange(of: scenePhase, initial: true) { _, phase in
                    if phase == .active {
                        AttributionService.shared.applicationDidBecomeActive()
                        SubscriptionAnalyticsService.shared.start()
                    } else if phase == .background {
                        AttributionService.shared.applicationDidEnterBackground()
                        AnalyticsService.shared.flush()
                    }
                }
        }
    }
}
