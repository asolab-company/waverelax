import SwiftUI

struct ConfiguredWebJourney: View {
    let includesOnboarding: Bool
    let onActivated: () -> Void
    let onFallback: () -> Void
    @Environment(AppEnvironment.self) private var app
    @State private var url: URL?
    @State private var completed = false

    var body: some View {
        Group {
            if let url { WaveWebSubscriptionScreen(url: url, onFailure: onFallback) }
            else { ZStack { PurpleWaveBackground(); ProgressView().tint(AppPalette.primary) } }
        }
        .task {
            if !app.store.hasRecentConfiguration { await app.store.refreshEntitlements() }
            guard !Task.isCancelled else { return }
            if app.store.isSubscribed { activate(); return }
            guard app.store.useWebPaywall else { onFallback(); return }
            do {
                let launch = try await WebSubscriptionClient.shared.launch(onboarding: includesOnboarding)
                guard !Task.isCancelled else { return }
                url = launch
            } catch { if !Task.isCancelled { onFallback() } }
        }
        .onChange(of: app.store.isSubscribed) { _, active in if active { activate() } }
    }
    private func activate() {
        guard !completed else { return }
        completed = true
        onActivated()
    }
}

struct ConfiguredPurchaseView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var native = false
    @State private var prepared = false

    var body: some View {
        Group {
            if native { PaywallScreen() }
            else if prepared {
                ConfiguredWebJourney(includesOnboarding: false,
                    onActivated: { dismiss() }, onFallback: { native = true })
            } else { ZStack { PurpleWaveBackground(); ProgressView().tint(AppPalette.primary) } }
        }
        .task {
            await app.store.preparePaywall()
            guard !Task.isCancelled else { return }
            if app.store.isSubscribed { dismiss(); return }
            native = !app.store.useWebPaywall
            prepared = true
        }
    }
}

struct RestoreWebSubscriptionView: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var url: URL?
    @State private var failed = false
    @State private var attempt = 0

    var body: some View {
        Group {
            if let url { WaveWebSubscriptionScreen(url: url, onFailure: { self.url = nil; failed = true }) }
            else if failed {
                ContentUnavailableView {
                    Label("Unable to load subscription access", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("Check your connection and try again.")
                } actions: {
                    Button("Retry") { failed = false; attempt += 1 }
                    Button("Close") { dismiss() }
                }
            } else { ZStack { PurpleWaveBackground(); ProgressView().tint(AppPalette.primary) } }
        }
        .task(id: attempt) {
            do {
                await app.store.refreshWebSubscription()
                url = try await WebSubscriptionClient.shared.launch(restore: true)
            } catch { if !Task.isCancelled { failed = true } }
        }
        .onChange(of: app.store.isSubscribed) { _, active in if active { dismiss() } }
    }
}
