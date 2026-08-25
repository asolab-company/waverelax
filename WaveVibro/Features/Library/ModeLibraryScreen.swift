import SwiftUI

struct ModeLibraryScreen: View {
    @Environment(AppEnvironment.self) private var app
    @Environment(\.scenePhase) private var scenePhase

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
    ]

    var body: some View {
        ZStack {
            GradientCanvas()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    Text("Library")
                        .font(AppTypography.regular(20))
                        .foregroundColor(.white)

                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(SoundModeCatalog.all) { mode in
                            let unlocked = app.store.isUnlocked(mode)
                            let isActive = app.session.isPlaying
                                && app.session.selectedMode?.id == mode.id

                            VStack(spacing: 10) {
                                ModeOrb(
                                    mode: mode,
                                    isSelected: isActive,
                                    isUnlocked: unlocked,
                                    diameter: 94,
                                    action: {
                                        if isActive {
                                            app.session.stop()
                                        } else {
                                            app.session.play(mode)
                                        }
                                    },
                                    onLockedTap: app.paywall.present
                                )

                                ModeOrbCaption(title: mode.title)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 116)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            app.session.handleScenePhase(newPhase, stopsOnInactive: true)
        }
        .onDisappear {
            app.session.leaveScreen()
        }
    }
}
