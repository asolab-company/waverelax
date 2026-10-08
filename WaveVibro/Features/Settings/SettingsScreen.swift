import SwiftUI
import UIKit

struct SettingsScreen: View {
    @Environment(AppEnvironment.self) private var app
    @State private var isHelpPresented = false
    @State private var isRatingPresented = false
    @State private var isWebRestorePresented = false
    @State private var notice: SettingsNotice?

    var body: some View {
        ZStack {
            GradientCanvas()

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    Text("Settings")
                        .font(AppTypography.regular(20))
                        .foregroundColor(.white)

                    if !app.store.isSubscribed {
                        premiumCard
                    }

                    VStack(spacing: 10) {
                        ForEach(rows) { row in
                            SettingsActionRow(row: row)
                        }
                    }
                    .padding(.top, 20)

                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $isWebRestorePresented) { RestoreWebSubscriptionView().environment(app) }
        .alert(notice?.title ?? "WaveVibro", isPresented: Binding(
            get: { notice != nil }, set: { if !$0 { notice = nil } }
        ), presenting: notice) { notice in
            if case .contact = notice {
                Button("Copy email") { UIPasteboard.general.string = "mail@origino.space" }
                Button("Close", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: { notice in Text(notice.message) }
        .sheet(isPresented: $isRatingPresented) {
            RatingPrompt { rating in
                isRatingPresented = false
                let destination = rating <= 3 ? AppLinks.support : AppLinks.appStoreReview
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    open(destination)
                }
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isHelpPresented) {
            HelpCenterScreen()
        }
    }

    private var premiumCard: some View {
        Button(action: app.paywall.presentNative) {
            HStack(spacing: 12) {
                Image("ic_vip")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)

                HStack(spacing: 0) {
                    Text("Become ")
                        .font(AppTypography.regular(20))
                    Text("Premium ")
                        .font(AppTypography.bold(20))
                    Text("User")
                        .font(AppTypography.regular(20))
                }
                .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var rows: [SettingsRow] {
        var items = [
            SettingsRow(icon: "app_ic_help", title: "Get Help") {
                isHelpPresented = true
            },
            SettingsRow(icon: "app_ic_rate", title: "Rate Us") {
                isRatingPresented = true
            },
            SettingsRow(icon: "app_ic_terms", title: "Terms and Conditions") {
                open(AppLinks.termsOfUse)
            },
            SettingsRow(icon: "app_ic_privacy", title: "Privacy") {
                open(AppLinks.privacyPolicy)
            },
        ]

        items.append(SettingsRow(icon: "app_ic_help", title: "Contact Us") {
            let url = URL(string: "mailto:mail@origino.space")!
            if UIApplication.shared.canOpenURL(url) { UIApplication.shared.open(url) }
            else { notice = .contact }
        })
        if !app.store.isSubscribed {
            items.append(SettingsRow(icon: "app_ic_restore", title: "Restore web subscription") { isWebRestorePresented = true })
            items.append(
                SettingsRow(icon: "app_ic_restore", title: "Restore Purchases") {
                    Task {
                        await app.store.restore()
                        if let message = app.store.errorMessage { notice = .subscription(message) }
                    }
                }
            )
        }
        return items
    }

    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }
}

private enum SettingsNotice {
    case contact
    case subscription(String)
    var title: String {
        switch self {
        case .contact: "Contact Us"
        case .subscription: "Subscription"
        }
    }
    var message: String {
        switch self {
        case .contact: "mail@origino.space"
        case .subscription(let message): message
        }
    }
}

private struct SettingsRow: Identifiable {
    let icon: String
    let title: String
    let action: () -> Void
    var id: String { title }
}

private struct SettingsActionRow: View {
    let row: SettingsRow

    var body: some View {
        Button(action: row.action) {
            HStack {
                Image(row.icon)
                    .frame(width: 24)

                Text(row.title)
                    .font(AppTypography.regular(16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 5)

                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.black.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct RatingPrompt: View {
    let onSelect: (Int) -> Void
    @State private var selectedRating = 0

    var body: some View {
        ZStack {
            GradientCanvas()

            VStack(spacing: 18) {
                Image("app_bg_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 54)

                Text("How is your WaveVibro experience?")
                    .font(AppTypography.bold(23))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)

                Text("Your feedback helps us make every session better.")
                    .font(AppTypography.regular(16))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.82))

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            selectedRating = rating
                            onSelect(rating)
                        } label: {
                            Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 34, weight: .medium))
                                .foregroundColor(rating <= selectedRating ? .yellow : .white)
                        }
                        .accessibilityLabel("\(rating) stars")
                    }
                }
            }
            .padding(.horizontal, 28)
        }
    }
}
