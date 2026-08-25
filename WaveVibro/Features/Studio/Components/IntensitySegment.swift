import SwiftUI

struct IntensitySegment: View {
    @Environment(AppEnvironment.self) private var app

    var body: some View {
        @Bindable var preferences = app.preferences

        HStack(spacing: 0) {
            ForEach(IntensityGrade.allCases) { grade in
                let isSelected = preferences.intensity == grade

                Button {
                    if app.store.isUnlocked(grade) {
                        preferences.intensity = grade
                    } else {
                        app.paywall.present()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(grade.title)
                            .foregroundColor(isSelected ? AppPalette.primary : .white)
                            .font(AppTypography.regular(16))

                        Spacer(minLength: 0)

                        if app.store.isUnlocked(grade) == false {
                            Image("ic_lock")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(isSelected ? AppPalette.primary : .white)
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, minHeight: 38, maxHeight: 38)
                    .background(segmentBackground(isSelected: isSelected, grade: grade))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(grade.title)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .frame(height: 46)
        .padding(.horizontal, 20)
        .onChange(of: app.store.isSubscribed) { _, isSubscribed in
            if !isSubscribed, preferences.intensity.requiresPremium {
                preferences.intensity = .easy
            }
        }
    }

    @ViewBuilder
    private func segmentBackground(isSelected: Bool, grade: IntensityGrade) -> some View {
        RoundedRectangle(cornerRadius: 23, style: .continuous)
            .fill(isSelected ? Color.white : tint(for: grade))
    }

    private func tint(for grade: IntensityGrade) -> Color {
        switch grade {
        case .easy:
            return Color.white.opacity(0.4)
        case .medium:
            return Color.white.opacity(0.3)
        case .strong:
            return Color.white.opacity(0.2)
        }
    }
}
