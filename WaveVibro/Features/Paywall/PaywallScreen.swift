import StoreKit
import SwiftUI
import UIKit

struct PaywallScreen: View {
    var onFinished: (() -> Void)? = nil
    @Environment(AppEnvironment.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: AccessPlan = .weekly
    @State private var isPurchasing = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                paywallBackground

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBar

                        VStack(spacing: 8) {
                            Text("Unlimited Access")
                                .font(AppTypography.heavy(30, relativeTo: .title))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text("Everything you need for your perfect sound session")
                                .font(AppTypography.regular(15))
                                .foregroundColor(.white.opacity(0.82))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 30)

                        Color.clear
                            .frame(height: max(geo.size.height * 0.065, 52))

                        VStack(spacing: 16) {
                            perksCard

                            VStack(spacing: 10) {
                                ForEach(AccessPlan.allCases, id: \.self) { plan in
                                    AccessPlanCard(
                                        title: plan.title,
                                        subtitle: subtitle(for: plan),
                                        badgeText: plan.badgeText,
                                        isSelected: selectedPlan == plan,
                                        style: plan.style
                                    ) {
                                        selectedPlan = plan
                                        AnalyticsService.shared.track("Plan Selected", properties: ["plan": plan.title])
                                    }
                                }
                            }

                            PrimaryCapsuleButton(
                                title: "Continue",
                                isBusy: isPurchasing,
                                isEnabled: !isPurchasing && product(for: selectedPlan) != nil,
                                action: purchase
                            )
                            .padding(.top, 2)

                            if let message = app.store.errorMessage {
                                Text(message).font(AppTypography.regular(13)).foregroundStyle(AppPalette.primaryDeep)
                                    .multilineTextAlignment(.center).accessibilityLabel(message)
                                if app.store.products.isEmpty && !app.store.isLoadingProducts {
                                    Button("Retry loading offers") { Task { await app.store.fetchProducts() } }
                                        .foregroundStyle(AppPalette.primary)
                                }
                            }
                            footerActions
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 24)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .task { await app.store.preparePaywall() }
        .onAppear { AnalyticsService.shared.track("Paywall Viewed", properties: ["source": onFinished == nil ? "settings_or_feature" : "startup"]) }
        .onChange(of: app.store.isSubscribed) { _, active in if active { finish() } }
    }

    private func finish() { if let onFinished { onFinished() } else { dismiss() } }

    private var paywallBackground: some View {
        ZStack(alignment: .top) {
            AppPalette.sheetBackground
                .ignoresSafeArea()

            StaticPaywallArtwork()
                .ignoresSafeArea()
        }
    }

    private var topBar: some View {
        ZStack {
            HStack {
                closeButton
                Spacer()
            }

            Text("WaveVibro")
                .font(AppTypography.medium(15))
                .foregroundColor(.white.opacity(0.82))
        }
        .frame(height: 44)
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var closeButton: some View {
        Button(action: finish) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.68))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .offset(y: -12)
        .accessibilityLabel("Close")
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            FeatureHighlightRow(
                icon: "ic_check",
                title: "All 12 sound modes",
                description: "Explore every sound world without limits"
            )

            Divider()
                .overlay(AppPalette.primary.opacity(0.10))

            FeatureHighlightRow(
                icon: "ic_check",
                title: "Every intensity level",
                description: "Adjust loudness to match your preference"
            )

            Divider()
                .overlay(AppPalette.primary.opacity(0.10))

            FeatureHighlightRow(
                icon: "ic_check",
                title: "Full playback control",
                description: "Set the pace from gentle to intense"
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
    }

    private var footerActions: some View {
        VStack(spacing: 13) {
            HStack(spacing: 8) {
                Image("ic_shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 19, height: 19)

                Text("Auto-renewable · Cancel anytime")
                    .font(AppTypography.medium(12))
            }
            .foregroundColor(AppPalette.primary)

            HStack(spacing: 26) {
                actionLink("Privacy") { open(AppLinks.privacyPolicy) }

                if !app.store.isSubscribed {
                    actionLink("Restore") {
                        Task {
                            await app.store.restore()
                            await app.store.refreshEntitlements()
                        }
                    }
                }

                actionLink("Terms") { open(AppLinks.termsOfUse) }
            }
        }
    }

    private func purchase() {
        guard let product = product(for: selectedPlan), !isPurchasing else { return }
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

    private func subtitle(for plan: AccessPlan) -> String {
        guard let product = product(for: plan) else { return "Loading price…" }
        return app.store.priceLine(for: product)
    }

    private func actionLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.regular(13))
                .foregroundColor(AppPalette.sheetMuted)
        }
        .buttonStyle(.plain)
    }

    private func product(for plan: AccessPlan) -> Product? {
        switch plan {
        case .weekly: return app.store.weeklyProduct
        case .yearly: return app.store.yearlyProduct
        }
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}

private struct StaticPaywallArtwork: View {
    var body: some View {
        GeometryReader { geo in
            Image("paywall_top")
                .resizable()
                .scaledToFit()
                .saturation(0)
                .colorMultiply(AppPalette.primary)
                .frame(width: geo.size.width * 1.14 + 4)
                .frame(width: geo.size.width, alignment: .top)
                .clipped()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum AccessPlan: CaseIterable {
    case weekly
    case yearly

    var title: String {
        switch self {
        case .weekly: return "Weekly Access"
        case .yearly: return "Yearly Access"
        }
    }

    var badgeText: String {
        switch self {
        case .weekly: return "POPULAR"
        case .yearly: return "BEST VALUE"
        }
    }

    var style: PlanCardStyle {
        switch self {
        case .weekly: return .popular
        case .yearly: return .featured
        }
    }
}

enum PlanCardStyle {
    case popular
    case featured
}

private struct AccessPlanCard: View {
    let title: String
    let subtitle: String
    let badgeText: String
    let isSelected: Bool
    let style: PlanCardStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(AppPalette.primary.opacity(isSelected ? 1 : 0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(AppPalette.primary)
                            .frame(width: 14, height: 14)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppTypography.medium(16))
                    Text(subtitle)
                        .font(AppTypography.regular(13))
                }
                .foregroundColor(.black)

                Spacer()

                Text(badgeText)
                    .font(AppTypography.bold(11))
                    .foregroundColor(style == .popular ? AppPalette.primary : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(style == .popular ? Color.white : AppPalette.primary)
                    )
            }
            .padding(.horizontal, 18)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(isSelected ? AppPalette.primary.opacity(0.13) : Color.white.opacity(0.48))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(
                        AppPalette.primary.opacity(isSelected ? 1 : 0.55),
                        lineWidth: isSelected ? 2.5 : 1.25
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
