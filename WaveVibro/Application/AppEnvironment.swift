import Foundation

@MainActor
@Observable
final class AppEnvironment {
    let store: StoreFront
    let session: SoundSession
    let preferences: PlaybackPreferences
    let paywall: PaywallPresenter
    let screenLock: ScreenLockPresenter

    init() {
        let preferences = PlaybackPreferences()
        let engine = LoopingPlaybackEngine()
        let session = SoundSession(engine: engine, preferences: preferences)

        self.store = StoreFront.shared
        self.preferences = preferences
        self.session = session
        self.paywall = PaywallPresenter()
        self.screenLock = ScreenLockPresenter()

        preferences.onChange = { [weak session] in
            session?.syncLiveAudioParameters()
        }

        session.prepare()
    }
}
