import SwiftUI

struct FeatureHighlightRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(icon)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTypography.heavy(16))
                    .foregroundColor(AppPalette.primary)
                    .shadow(color: .white.opacity(0.8), radius: 1, y: 1)

                Text(description)
                    .font(AppTypography.regular(14))
                    .foregroundColor(AppPalette.primary)
                    .shadow(color: .white.opacity(0.8), radius: 1, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
