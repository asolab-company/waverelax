import SwiftUI
import UIKit

struct OnboardingContainer: View {
    @State private var page = 0
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
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            PageDots(count: 3, current: page)

            PrimaryCapsuleButton(title: page == 2 ? "Start Listening" : "Continue") {
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
                .frame(height: 42)
        }
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private func completeFlow() {
        OnboardingStore.markCompleted()
        onFinished()
    }
}

struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AppPalette.primary : Color.gray.opacity(0.28))
                    .frame(width: index == current ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}

private struct OnboardingLegalFooter: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("By proceeding, you accept")
                .foregroundColor(AppPalette.sheetMuted)
                .font(AppTypography.medium(12))

            HStack(spacing: 18) {
                legalLink("Terms of Use", url: AppLinks.termsOfUse)
                legalLink("Privacy Policy", url: AppLinks.privacyPolicy)
            }
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
