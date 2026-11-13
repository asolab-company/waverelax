import StoreKit
import SwiftUI
import UIKit

struct PaywallScreen: View {
    var onFinished: (() -> Void)? = nil
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            PremiumPaywallBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar
                    introduction
                        .modifier(PaywallEntrance(isVisible: hasAppeared))

                    LazyVGrid(columns: columns, spacing: 12) {
                        PremiumPaywallTile(artwork: "paywall_modes", title: "All 12 modes", detail: "Explore every sound & vibration rhythm")
                            .modifier(PaywallEntrance(isVisible: hasAppeared, delay: 0.04))
                        PremiumPaywallTile(artwork: "paywall_intensity", title: "Every intensity", detail: "From gentle pulses to a stronger feel")
                            .modifier(PaywallEntrance(isVisible: hasAppeared, delay: 0.08))
                        PremiumPaywallTile(artwork: "paywall_control", title: "Full control", detail: "Fine-tune the pace of every session")
                            .modifier(PaywallEntrance(isVisible: hasAppeared, delay: 0.12))
                        PremiumPaywallTile(artwork: "paywall_weekly", title: "Weekly Access", detail: weeklyPrice)
                            .accessibilityIdentifier("paywall.weeklyOffer")
                            .modifier(PaywallEntrance(isVisible: hasAppeared, delay: 0.16))
                    }

                    Text("Subscription auto-renews. Cancel anytime.")
                        .font(AppTypography.regular(12))
                        .foregroundStyle(PaywallStyle.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                purchaseActions
            }
        }
        .task { await app.store.preparePaywall() }
        .onAppear {
            hasAppeared = true
            AnalyticsService.shared.track("Paywall Viewed", properties: [
                "source": onFinished == nil ? "settings_or_feature" : "startup",
                "format": "native_grid_weekly"
            ])
        }
        .onChange(of: app.store.isSubscribed) { _, active in if active { finish() } }
        .interactiveDismissDisabled(isPurchasing || isRestoring)
    }

    private var columns: [GridItem] {
        if dynamicTypeSize.isAccessibilitySize {
            [GridItem(.flexible(), alignment: .topLeading)]
        } else {
            [GridItem(.flexible(), spacing: 12, alignment: .topLeading), GridItem(.flexible(), spacing: 12, alignment: .topLeading)]
        }
    }

    private var introduction: some View {
        VStack(spacing: 12) {
            Text("Unlimited Access")
                .font(AppTypography.medium(32))
                .tracking(-0.7)
                .foregroundStyle(.white)

            Text("Your perfect sound & vibration session")
                .font(AppTypography.regular(15))
                .foregroundStyle(.white.opacity(0.85))
                .frame(maxWidth: 270)

            SessionWaveform()
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.1), .white.opacity(0.8), .white.opacity(0.1)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                )
                .frame(width: 152, height: 24)
                .padding(.top, 6)
                .accessibilityHidden(true)
        }
        .multilineTextAlignment(.center)
    }

    private var weeklyPrice: String {
        guard let product = app.store.weeklyProduct else {
            return app.store.isLoadingProducts ? "Loading price…" : "Offer unavailable"
        }
        return app.store.priceLine(for: product)
    }

    private var topBar: some View {
        HStack(spacing: 7) {
            Image(systemName: "waveform")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .accessibilityHidden(true)
            Text("WaveRelax")
                .font(AppTypography.medium(15))
                .tracking(0.4)
                .foregroundStyle(.white)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .frame(maxWidth: .infinity, minHeight: 44)
        .padding(.top, 4)
    }

    private var purchaseActions: some View {
        VStack(spacing: 8) {
            if let message = app.store.errorMessage {
                VStack(spacing: 6) {
                    Text(message)
                        .font(AppTypography.regular(13))
                        .multilineTextAlignment(.center)
                    if app.store.products.isEmpty && !app.store.isLoadingProducts {
                        Button("Retry loading offers") { Task { await app.store.fetchProducts() } }
                            .font(AppTypography.medium(14))
                            .frame(minHeight: 44)
                    }
                }
                .foregroundStyle(PaywallStyle.foreground)
            }

            Button(action: purchase) {
                HStack(spacing: 12) {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    }
                    Text(isPurchasing ? "Processing…" : "Continue")
                        .font(AppTypography.medium(17))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .medium))
                        .accessibilityHidden(true)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppPalette.primary)
                        .overlay {
                            PaywallButtonShimmer(isEnabled: !isPurchasing && !isRestoring && app.store.weeklyProduct != nil)
                                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        }
                }
                .contentShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
            .buttonStyle(PaywallPurchaseButtonStyle())
            .disabled(isPurchasing || isRestoring || app.store.weeklyProduct == nil)
            .opacity(isPurchasing || isRestoring || app.store.weeklyProduct == nil ? 0.55 : 1)
            .accessibilityIdentifier("paywall.continue")

            footerActions
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .background {
            PaywallStyle.background
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle().fill(PaywallStyle.foreground.opacity(0.07)).frame(height: 0.5)
                }
        }
    }

    private var footerActions: some View {
        HStack(spacing: 0) {
            actionLink("Privacy") { open(AppLinks.privacyPolicy) }
            Spacer(minLength: 8)
            actionLink("Skip", action: finish)
            Spacer(minLength: 8)
            actionLink(isRestoring ? "Restoring…" : "Restore") {
                guard !isRestoring else { return }
                isRestoring = true
                Task {
                    await app.store.restore()
                    isRestoring = false
                }
            }
            Spacer(minLength: 8)
            actionLink("Terms") { open(AppLinks.termsOfUse) }
        }
        .disabled(isPurchasing || isRestoring)
    }

    private func actionLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.regular(12))
                .foregroundStyle(PaywallStyle.secondary)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private func purchase() {
        guard let product = app.store.weeklyProduct, !isPurchasing else { return }
        isPurchasing = true
        Task {
            let outcome = await app.store.purchase(product: product)
            isPurchasing = false
            switch outcome {
            case .success: finish()
            case .pending: app.store.errorMessage = "Your purchase is awaiting confirmation. Access will update automatically."
            case .failed(let message): app.store.errorMessage = message
            case .cancelled: break
            }
        }
    }

    private func finish() { if let onFinished { onFinished() } else { dismiss() } }
    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}

private struct PremiumPaywallTile: View {
    let artwork: String
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(artwork)
                .resizable()
                .scaledToFit()
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                Text(title)
                    .font(AppTypography.medium(16))
                    .foregroundStyle(PaywallStyle.foreground)
                Text(detail)
                    .font(AppTypography.regular(13))
                    .foregroundStyle(PaywallStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 184, alignment: .topLeading)
        .background(PaywallStyle.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppPalette.primary.opacity(0.18), lineWidth: 0.75)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PremiumPaywallBackground: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack(alignment: .top) {
            AppPalette.sheetBackground.ignoresSafeArea()
            GeometryReader { geometry in
                Image("paywall_top")
                    .resizable()
                    .scaledToFit()
                    .saturation(0)
                    .colorMultiply(AppPalette.primary)
                    .frame(width: geometry.size.width * 1.14 + 4)
                    .frame(width: geometry.size.width, alignment: .top)
                    .clipped()
                    .scaleEffect(x: 1, y: dynamicTypeSize.isAccessibilitySize ? 2 : 1.15, anchor: .top)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct SessionWaveform: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for index in 0...160 {
            let progress = Double(index) / 160
            let envelope = pow(sin(progress * .pi), 2)
            let wave = sin(progress * .pi * 12) * envelope
            let point = CGPoint(x: rect.minX + rect.width * progress, y: rect.midY + wave * rect.height * 0.45)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }
}

private struct PaywallPurchaseButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .animation(reduceMotion ? nil : PaywallMotion.press, value: configuration.isPressed)
    }
}

private struct PaywallEntrance: ViewModifier {
    let isVisible: Bool
    var delay: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(reduceMotion || isVisible ? 1 : 0.8)
            .offset(y: reduceMotion || isVisible ? 0 : 6)
            .animation(reduceMotion ? nil : PaywallMotion.arrival.delay(delay), value: isVisible)
    }
}

private struct PaywallButtonShimmer: View {
    let isEnabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var pass = 0

    private var isAnimating: Bool { isEnabled && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { geometry in
            if isAnimating {
                Rectangle()
                    .fill(LinearGradient(colors: [.clear, .white.opacity(0.18), .clear], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geometry.size.width * 0.35, height: geometry.size.height * 2)
                    .rotationEffect(.degrees(18))
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .phaseAnimator([false, true], trigger: pass) { content, crossed in
                        content.offset(x: (crossed ? 1 : -1) * geometry.size.width)
                    } animation: { crossed in
                        crossed ? .linear(duration: 1.2) : nil
                    }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: isAnimating) {
            guard isAnimating else { return }
            do {
                try await Task.sleep(for: .seconds(4.5))
                while !Task.isCancelled {
                    pass += 1
                    try await Task.sleep(for: .seconds(6))
                }
            } catch { return }
        }
    }
}

private enum PaywallMotion {
    static let arrival = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.28)
    static let press = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.14)
}

private enum PaywallStyle {
    static let background = AppPalette.sheetBackground
    static let surface = Color.white
    static let foreground = AppPalette.primaryDeep
    static let secondary = AppPalette.primaryDeep.opacity(0.8)
}
