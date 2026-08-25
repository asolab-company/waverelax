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

}
