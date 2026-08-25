import SwiftUI

struct ModeCarousel: View {
    @Environment(AppEnvironment.self) private var app
    let hidesSelection: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(SoundModeCatalog.all) { mode in
                    let unlocked = app.store.isUnlocked(mode)

                    VStack(spacing: 8) {
                        ModeOrb(
                            mode: mode,
                            isSelected: !hidesSelection && app.session.selectedMode?.id == mode.id,
                            isUnlocked: unlocked,
                            action: {
                                app.session.select(mode)
                            },
                            onLockedTap: {
                                app.paywall.present()
                            }
                        )

                        ModeOrbCaption(title: mode.title)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 20)
        }
    }
}
