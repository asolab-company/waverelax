import SwiftUI

struct FrostedScrim: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        AppPalette.overlayScrim.opacity(0.18),
                        AppPalette.overlayScrim.opacity(0.38),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}
