import SwiftUI

struct LightSheetBackground: View {
    var imageName: String = "onb_top"

    var body: some View {
        ZStack(alignment: .top) {
            AppPalette.sheetBackground.ignoresSafeArea()
            Image(imageName)
                .resizable()
                .scaledToFit()
                .ignoresSafeArea()
        }
    }
}

struct PurpleWaveBackground: View {
    var body: some View {
        ZStack(alignment: .top) {
            AppPalette.sheetBackground
                .ignoresSafeArea()

            GeometryReader { geo in
                Image("paywall_top")
                    .resizable()
                    .scaledToFit()
                    .saturation(0)
                    .colorMultiply(AppPalette.primary)
                    .frame(width: geo.size.width * 1.14 + 4)
                    .frame(width: geo.size.width, alignment: .top)
                    .clipped()
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .ignoresSafeArea()
        }
    }
}
