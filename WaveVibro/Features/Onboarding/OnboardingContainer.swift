import SwiftUI
import UIKit

struct OnboardingContainer: View {
    @Environment(AppEnvironment.self) private var app
    @State private var page = 0
    @State private var preparing = false
    var onFinished: () -> Void

    var body: some View {
        ZStack {
            PurpleWaveBackground()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    WelcomeOnboardingPage().tag(0)
                    ControlOnboardingPage().tag(1)
                    CustomizeOnboardingPage().tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .task { await app.store.preparePaywall() }
        .onAppear { AnalyticsService.shared.track("Onboarding Started") }
        .onChange(of: page) { _, value in AnalyticsService.shared.track("Onboarding Step Viewed", properties: ["step": value + 1]) }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            PageDots(count: 3, current: page)

            PrimaryCapsuleButton(title: "Continue", isBusy: preparing, isEnabled: !preparing) {
                if page < 2 {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        page += 1
                    }
                } else {
                    completeFlow()
                }
            }
            .padding(.horizontal, 30)

            OnboardingLegalFooter()
                .opacity(page == 0 ? 1 : 0)
                .allowsHitTesting(page == 0)
                .accessibilityHidden(page != 0)
                .frame(height: 42)
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func completeFlow() {
        preparing = true
        Task {
            await app.store.preparePaywall()
            guard !Task.isCancelled else { return }
            OnboardingStore.markCompleted()
            AnalyticsService.shared.track("Onboarding Completed")
            onFinished()
        }
    }
}

struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? AppPalette.primary : Color.gray.opacity(0.28))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

private struct OnboardingLegalFooter: View {
    var body: some View {
        VStack(spacing: 2) {
            Text("By Proceeding You Accept")
                .foregroundColor(AppPalette.sheetMuted)
                .font(AppTypography.medium(12))

            HStack(spacing: 4) {
                Text("Our")
                legalLink("Terms Of Use", url: AppLinks.termsOfUse)
                Text("And")
                legalLink("Privacy Policy", url: AppLinks.privacyPolicy)
            }
            .foregroundStyle(AppPalette.sheetMuted)
            .font(AppTypography.medium(12))
        }
        .multilineTextAlignment(.center)
    }

    private func legalLink(_ title: String, url: URL?) -> some View {
        Button(title) {
            open(url)
        }
        .foregroundColor(AppPalette.primary)
        .font(AppTypography.medium(12))
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}
