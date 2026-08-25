import SwiftUI

struct PrimaryCapsuleButton: View {
    let title: String
    var isBusy: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(isBusy ? "Processing..." : title)
                    .foregroundColor(.white)
                    .font(AppTypography.bold(18))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
            }
            .padding()
            .background(AppPalette.primary)
            .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
        }
        .frame(height: 55)
        .disabled(!isEnabled || isBusy)
        .opacity(!isEnabled || isBusy ? 0.7 : 1)
    }
}
