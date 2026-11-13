import SwiftUI

struct WelcomeOnboardingPage: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    OnboardingArtwork(name: "onboarding_welcome")
                        .frame(width: min(geometry.size.width * 0.54, 230), height: min(geometry.size.width * 0.54, 230))
                        .padding(.top, geometry.size.height * 0.1)

                    OnboardingHeading(title: "Welcome to\nthe WaveRelax")
                        .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 14) {
                        OnboardingFeatureRow(
                            icon: "ic_time",
                            title: "Pre-programmed Sessions",
                            description: "Take advantage of pre-programmed sessions specially designed for you."
                        )
                        OnboardingFeatureRow(
                            icon: "ic_bolt",
                            title: "Intensity Control",
                            description: "Easily adjust the intensity of massage sessions to match your comfort level."
                        )
                        OnboardingFeatureRow(
                            icon: "ic_speed",
                            title: "Speed Control",
                            description: "Easily change the speed of massage patterns to get the best experience."
                        )
                    }
                    .padding(20)
                    .background(AppPalette.primary.opacity(0.14), in: RoundedRectangle(cornerRadius: 24))
                    .padding(.top, 24)
                    .padding(.horizontal, geometry.size.width * 0.06)
                }
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

struct ControlOnboardingPage: View {
    var body: some View {
        IllustratedOnboardingPage(
            imageName: "onb_2",
            title: "Stay in\nControl",
            description: "Use screen lock to prevent accidental interruptions and enjoy uninterrupted relaxation."
        )
    }
}

struct CustomizeOnboardingPage: View {
    var body: some View {
        IllustratedOnboardingPage(
            imageName: "onb_3",
            title: "Customize your\nexperience",
            description: "Choose from 12 unique vibration modes and easily adjust the speed and intensity to match your mood."
        )
    }
}

private struct IllustratedOnboardingPage: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    OnboardingArtwork(name: imageName)
                        .frame(height: min(geometry.size.height * 0.77, geometry.size.width * 1.3))

                    OnboardingHeading(title: title)
                        .padding(.top, 20)

                    Text(description)
                        .font(AppTypography.regular(14))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .padding(.horizontal, geometry.size.width * 0.06)
                }
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct OnboardingArtwork: View {
    let name: String

    private var image: some View {
        Image(name)
            .resizable()
            .scaledToFit()
    }

    var body: some View {
        image
            .overlay {
                AppPalette.primary.blendMode(.color)
            }
            .compositingGroup()
            .mask(image)
            .accessibilityHidden(true)
    }
}

private struct OnboardingHeading: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTypography.heavy(28, relativeTo: .largeTitle))
            .foregroundStyle(AppPalette.primary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
            .frame(maxWidth: .infinity)
    }
}

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.heavy(16))
                Text(description)
                    .font(AppTypography.regular(14))
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(AppPalette.primary)
        .accessibilityElement(children: .combine)
    }
}
