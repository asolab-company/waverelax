import SwiftUI

struct RootFlowView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    @State private var stage: LaunchStage = .splash

    var body: some View {
        Group {
            switch stage {
            case .splash:
                LaunchScreen {
                    Task { stage = await LaunchDestinationResolver.resolve(store: app.store) }
                }
            case .onboarding:
                OnboardingContainer {
                    stage = app.store.isSubscribed ? .shell : app.store.useWebPaywall ? .webPaywall : .nativePaywall
                    if app.store.isSubscribed { finishJourney() }
                }
            case .nativePaywall:
                PaywallScreen(onFinished: finishJourney)
            case .webOnboarding, .webPaywall:
                ConfiguredWebJourney(includesOnboarding: stage == .webOnboarding,
                    onActivated: finishJourney,
                    onFallback: { stage = LaunchDestinationResolver.nativeDestination })
            case .shell:
                AppShellView()
            }
        }
        .environment(app)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, stage != .splash {
                Task { await app.store.refreshEntitlements() }
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(60)) } catch { return }
                await app.store.refreshEntitlements()
            }
        }
        .onChange(of: app.store.isSubscribed) { _, active in
            if active, stage != .splash, stage != .shell { finishJourney() }
        }
    }
    private func finishJourney() {
        OnboardingStore.markJourneyCompleted()
        stage = .shell
    }
}
