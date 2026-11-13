import SwiftUI

struct StudioScreen: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLockArmed = false

    var body: some View {
        ZStack(alignment: .top) {
            GradientCanvas()

            VStack(alignment: .leading, spacing: 10) {
                StudioHeader(showsPremiumEntry: !app.store.isSubscribed) {
                    app.paywall.present()
                }

                IntensitySegment()
                TempoTrack()
                vibrationControl
                ModeCarousel(hidesSelection: app.screenLock.isPresented)

                Spacer()

                PowerCluster(isLockArmed: $isLockArmed)
                    .padding(.bottom, 100)

                Spacer()
            }
            .padding(.top, 20)
        }
        .onAppear {
            if app.session.selectedMode == nil,
               let firstAvailable = SoundModeCatalog.all.first(where: { app.store.isUnlocked($0) }) {
                app.session.select(firstAvailable)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            app.session.handleScenePhase(newPhase, stopsOnInactive: false)
        }
        .onChange(of: app.screenLock.isPresented) { _, visible in
            if !visible {
                isLockArmed = false
            }
        }
        .onDisappear {
            app.session.leaveScreen()
        }
    }

    private var vibrationControl: some View {
        @Bindable var preferences = app.preferences
        return VStack(alignment: .leading, spacing: 4) {
            Toggle("Vibrations", isOn: $preferences.vibrationsEnabled)
                .font(AppTypography.medium(15))
                .tint(.white.opacity(0.35))
                .foregroundStyle(.white)
                .disabled(!app.session.haptics.isSupported)
            if !app.session.haptics.isSupported {
                Text("Vibrations require a supported iPhone.")
                    .font(AppTypography.regular(12))
                    .foregroundStyle(.white.opacity(0.75))
            } else if let message = app.session.haptics.errorMessage {
                Text(message).font(AppTypography.regular(12)).foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 28)
    }
}
