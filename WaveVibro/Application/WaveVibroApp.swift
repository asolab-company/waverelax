import SwiftUI

@main
struct WaveVibroApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .environment(environment)
        }
    }
}
