import SwiftUI

struct WelcomeOnboardingPage: View {
    var body: some View {
        OnboardingPageFrame(
            hero: {
                VStack(spacing: 16) {
                    Image("onboarding_audio_v2")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 176)

                    VStack(spacing: 8) {
                        Text("Welcome to\nWaveVibro")
                            .font(AppTypography.heavy(28, relativeTo: .largeTitle))
                            .foregroundColor(AppPalette.primary)
                            .multilineTextAlignment(.center)

                        Text("A guided audio space for mood, rhythm, and focused relaxation.")
                            .font(AppTypography.regular(15))
                            .foregroundColor(.black.opacity(0.72))
                            .multilineTextAlignment(.center)
                    }
                }
            },
            bodyContent: {
                VStack(spacing: 12) {
                    FeatureHighlightRow(
                        icon: "ic_time",
                        title: "Ready-made Sessions",
                        description: "Start quickly with sound scenes built for calm, focus, and reset."
                    )
                    FeatureHighlightRow(
                        icon: "ic_bolt",
                        title: "Intensity Control",
                        description: "Shape each session from soft ambience to a fuller, stronger feel."
                    )
                    FeatureHighlightRow(
                        icon: "ic_speed",
                        title: "Speed Control",
                        description: "Slow things down or increase the pace until it matches your mood."
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(AppPalette.primary.opacity(0.14))
                )
            }
        )
    }
}

struct ControlOnboardingPage: View {
    var body: some View {
        OnboardingPageFrame(
            hero: {
                Image("onboarding_lock_v2")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 276)
            },
            bodyContent: {
                VStack(spacing: 12) {
                    Text("Stay in\nControl")
                        .font(AppTypography.heavy(28, relativeTo: .largeTitle))
                        .foregroundColor(AppPalette.primary)
                        .multilineTextAlignment(.center)

                    Text("Use screen lock to prevent accidental interruptions and keep your session flowing.")
                        .font(AppTypography.regular(15))
                        .foregroundColor(.black.opacity(0.72))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 10) {
                        BenefitChip(text: "Lock Screen")
                        BenefitChip(text: "Hands-Free")
                        BenefitChip(text: "No Interruptions")
                    }
                    .padding(.top, 4)
                }
            }
        )
    }
}

struct CustomizeOnboardingPage: View {
    var body: some View {
        OnboardingPageFrame(
            hero: {
                Image("onboarding_customize_v2")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 276)
            },
            bodyContent: {
                VStack(spacing: 12) {
                    Text("Make it\nyours")
                        .font(AppTypography.heavy(28, relativeTo: .largeTitle))
                        .foregroundColor(AppPalette.primary)
                        .multilineTextAlignment(.center)

                    Text("Pick from 12 sound modes and fine-tune speed and intensity until it feels right.")
                        .font(AppTypography.regular(15))
                        .foregroundColor(.black.opacity(0.72))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        MiniStat(title: "Modes", value: "12")
                        MiniStat(title: "Speed", value: "Live")
                        MiniStat(title: "Intensity", value: "3")
                    }
                    .padding(.top, 4)
                }
            }
        )
    }
}

private struct OnboardingPageFrame<Hero: View, BodyContent: View>: View {
    @ViewBuilder let hero: Hero
    @ViewBuilder let bodyContent: BodyContent

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    hero
                    bodyContent
                }
                .padding(.horizontal, geo.size.width * 0.07)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geo.size.height, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct BenefitChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.medium(12))
            .foregroundColor(AppPalette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(AppPalette.primary.opacity(0.12))
            )
    }
}

private struct MiniStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(AppTypography.bold(16))
                .foregroundColor(AppPalette.primary)
            Text(title)
                .font(AppTypography.regular(11))
                .foregroundColor(.black.opacity(0.56))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
    }
}
