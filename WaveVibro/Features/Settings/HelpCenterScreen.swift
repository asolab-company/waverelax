import SwiftUI

struct HelpCenterScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var expandedTopic: HelpTopic.ID? = HelpTopic.all.first?.id

    var body: some View {
        ZStack {
            GradientCanvas()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    introduction

                    VStack(spacing: 12) {
                        ForEach(HelpTopic.all) { topic in
                            HelpDisclosureCard(
                                topic: topic,
                                isExpanded: expandedTopic == topic.id
                            ) {
                                withAnimation(.snappy(duration: 0.32, extraBounce: 0.04)) {
                                    expandedTopic = expandedTopic == topic.id ? nil : topic.id
                                }
                            }
                        }
                    }

                    supportButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 34)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button(action: dismiss.callAsFunction) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.black.opacity(0.16)))
                    .overlay(Circle().stroke(Color.white.opacity(0.24), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")

            Text("Get Help")
                .font(AppTypography.bold(24))
                .foregroundStyle(.white)

            Spacer()
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WaveVibro guide")
                .font(AppTypography.heavy(30, relativeTo: .largeTitle))
                .foregroundStyle(.white)

            Text("Tap a topic to learn how sound modes and session controls work.")
                .font(AppTypography.regular(16))
                .foregroundStyle(.white.opacity(0.76))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }

    private var supportButton: some View {
        Button {
            if let url = AppLinks.support {
                openURL(url)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 18, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Still need help?")
                        .font(AppTypography.bold(16))
                    Text("Contact support")
                        .font(AppTypography.regular(14))
                        .opacity(0.72)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.16))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct HelpDisclosureCard: View {
    let topic: HelpTopic
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.white.opacity(0.16)))

                    Text(topic.title)
                        .font(AppTypography.bold(17))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    Image(systemName: isExpanded ? "minus" : "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.black.opacity(0.14)))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                Text(topic.details)
                    .font(AppTypography.regular(15))
                    .foregroundStyle(.white.opacity(0.78))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 52)
                    .padding(.top, 12)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(isExpanded ? 0.2 : 0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isExpanded ? 0.34 : 0.15), lineWidth: 1)
        )
    }
}

private struct HelpTopic: Identifiable {
    let id: String
    let icon: String
    let title: String
    let details: String

    static let all: [HelpTopic] = [
        HelpTopic(
            id: "about",
            icon: "waveform",
            title: "What is WaveVibro?",
            details: "WaveVibro is a collection of looping sound sessions designed for relaxation, focus, and resetting your pace. Choose a sound world, tune it, and start or stop the session whenever you like."
        ),
        HelpTopic(
            id: "modes",
            icon: "circle.grid.2x2.fill",
            title: "How do sound modes work?",
            details: "The app includes 12 sound modes. Choose one in Studio or Library, then tap its orb to begin playback. Tap the active mode again or use the large power button to stop."
        ),
        HelpTopic(
            id: "intensity",
            icon: "speaker.wave.2.fill",
            title: "What do intensity levels change?",
            details: "Easy, Medium, and Hard adjust the loudness of your session. Easy is available to everyone; the additional levels are included with Premium."
        ),
        HelpTopic(
            id: "speed",
            icon: "gauge.with.dots.needle.50percent",
            title: "What does speed control do?",
            details: "Move the speed slider toward the breeze for a gentler pace or toward the vortex for a faster, more energetic loop. Premium unlocks the full speed range."
        ),
        HelpTopic(
            id: "lock",
            icon: "lock.fill",
            title: "How does screen lock work?",
            details: "Tap the lock beside the power control during a session to prevent accidental touches. To return, swipe the lock screen upward until it closes."
        ),
        HelpTopic(
            id: "premium",
            icon: "crown.fill",
            title: "What does Premium unlock?",
            details: "Premium unlocks all 12 sound modes, every intensity level, and the complete playback-speed range. You can manage or cancel your subscription in your Apple ID settings."
        ),
        HelpTopic(
            id: "restore",
            icon: "arrow.clockwise",
            title: "How do I restore a purchase?",
            details: "Open Settings and tap Restore Purchases. Use the same Apple ID that originally purchased the subscription, then allow a moment for access to update."
        ),
    ]
}
