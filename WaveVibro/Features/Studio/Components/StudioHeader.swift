import SwiftUI

struct StudioHeader: View {
    let showsPremiumEntry: Bool
    let onPremiumTap: () -> Void

    var body: some View {
        HStack {
            Text("WaveVibro")
                .font(AppTypography.heavy(20))
                .foregroundColor(AppPalette.onCanvas)

            Spacer()

            if showsPremiumEntry {
                Button(action: onPremiumTap) {
                    Image("ic_vip")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Become Premium")
            }
        }
        .padding(.horizontal, 20)
    }
}
