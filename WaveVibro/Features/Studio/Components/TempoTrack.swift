import SwiftUI

struct TempoTrack: View {
    @Environment(AppEnvironment.self) private var app
    @State private var didOfferLockedRange = false
    @State private var isDragging = false

    var body: some View {
        @Bindable var preferences = app.preferences

        HStack(spacing: 16) {
            Image("ic_s_left")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.white)
                .padding(.leading, 12)

            GeometryReader { geometry in
                let width = geometry.size.width
                let progress = CGFloat(preferences.tempo / TempoLimits.absoluteMaximum)
                let clampedProgress = min(max(progress, 0), 1)
                let premiumStartX = width * CGFloat(TempoLimits.freeProgressCeiling)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)

                    Capsule()
                        .fill(Color.white)
                        .frame(width: max(clampedProgress * width, 8), height: 8)

                    if !app.store.isSubscribed {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, Color.white.opacity(0.14)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(width - premiumStartX, 0), height: 8)
                            .offset(x: premiumStartX)

                        premiumLock(at: width / 2)
                        premiumLock(at: width - 10)
                    }

                    knob
                        .offset(x: clampedProgress * width - 17)
                        .scaleEffect(isDragging ? 1.06 : 1)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            isDragging = true
                        }
                        .onChanged { gesture in
                            let normalized = min(max(gesture.location.x / width, 0), 1)
                            let maxProgress = app.store.isSubscribed
                                ? 1.0
                                : CGFloat(TempoLimits.freeProgressCeiling)

                            if !app.store.isSubscribed,
                               normalized > CGFloat(TempoLimits.freeProgressCeiling),
                               !didOfferLockedRange {
                                didOfferLockedRange = true
                                app.paywall.present()
                            }

                            preferences.tempo = Float(min(normalized, maxProgress)) * TempoLimits.absoluteMaximum
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 28)
            .padding(.horizontal, 5)
            .accessibilityLabel("Playback speed")

            Image("ic_s_right")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.white)
                .padding(.trailing, 12)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 20)
        .onAppear {
            app.preferences.clampTempo(hasPremiumAccess: app.store.isSubscribed)
        }
        .onChange(of: app.store.isSubscribed) { _, isSubscribed in
            didOfferLockedRange = false
            app.preferences.clampTempo(hasPremiumAccess: isSubscribed)
        }
    }

    private var knob: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 28, height: 28)
            Circle()
                .stroke(AppPalette.primary, lineWidth: 3.5)
                .frame(width: 20, height: 20)
        }
        .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
    }

    private func premiumLock(at x: CGFloat) -> some View {
        Image("ic_lock")
            .resizable()
            .scaledToFit()
            .foregroundColor(.white.opacity(0.72))
            .frame(width: 24, height: 24)
            .position(x: x, y: 14)
    }
}
