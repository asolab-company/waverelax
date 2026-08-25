import SwiftUI

struct LaunchScreen: View {
    var onFinished: () -> Void
    @State private var progress: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width * 0.6
            let iconWidth = geometry.size.width * 0.54

            ZStack {
                GradientCanvas()

                VStack(spacing: 0) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: iconWidth + 70, height: iconWidth + 70)
                            .blur(radius: 4)
                            .scaleEffect(pulse ? 1.06 : 0.94)
                        Image("app_bg_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: iconWidth)
                    }

                    VStack(spacing: 8) {
                        Text("WaveVibro")
                            .font(AppTypography.heavy(30))
                            .foregroundColor(AppPalette.onCanvas)
                        Text("Preparing your sound space")
                            .font(AppTypography.regular(14))
                            .foregroundColor(AppPalette.onCanvasMuted)
                    }
                    .padding(.top, 22)

                    Spacer()

                    VStack(spacing: 12) {
                        HStack {
                            Text("Loading")
                                .font(AppTypography.medium(15))
                                .foregroundColor(AppPalette.onCanvas)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(AppTypography.bold(16))
                                .foregroundColor(AppPalette.onCanvas)
                        }
                        .frame(width: barWidth)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.16))
                                .frame(width: barWidth, height: 10)

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, AppPalette.primaryGlow],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(barWidth * progress, 10), height: 10)
                                .animation(.easeInOut(duration: 0.18), value: progress)
                        }
                    }
                    .padding(.bottom, 56)
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            progress = 0
            pulse = true

            for step in 1...100 {
                try? await Task.sleep(nanoseconds: 20_000_000)
                guard !Task.isCancelled else { return }
                progress = CGFloat(step) / 100
            }

            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            onFinished()
        }
    }
}
