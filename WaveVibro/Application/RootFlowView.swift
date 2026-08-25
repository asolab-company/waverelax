import SwiftUI

struct RootFlowView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var stage: LaunchStage = .splash

    var body: some View {
        Group {
            switch stage {
            case .splash:
                LaunchScreen {
                    Task {
                        stage = await LaunchDestinationResolver.resolve(store: app.store)
                    }
                }
            case .onboarding:
                OnboardingContainer {
                    stage = .shell
                }
            case .shell:
                AppShellView()
            }
        }
        .environment(app)
    }
}
