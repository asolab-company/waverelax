import SwiftUI

struct ModeOrb: View {
    let mode: SoundMode
    let isSelected: Bool
    let isUnlocked: Bool
    var diameter: CGFloat = 70
    let action: () -> Void
    let onLockedTap: () -> Void

    var body: some View {
        Button {
            if isUnlocked {
                action()
            } else {
                onLockedTap()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.4))
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )
                    .frame(width: diameter, height: diameter)

                Image(mode.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .scaledToFit()
                    .frame(width: diameter * 0.54, height: diameter * 0.54)

                if !isUnlocked {
                    lockBadge
                        .offset(x: diameter * 0.43, y: -diameter * 0.4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isUnlocked ? "Plays the \(mode.title) sound" : "Locked. Opens premium access.")
    }

    private var lockBadge: some View {
        ZStack {
            Circle()
                .fill(AppPalette.primary)
                .frame(width: 34, height: 34)
            Image("ic_lock")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
    }
}

struct ModeOrbCaption: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTypography.regular(14))
            .foregroundColor(AppPalette.onCanvas)
    }
}
