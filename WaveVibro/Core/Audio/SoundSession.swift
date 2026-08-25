import AVFoundation
import Foundation
import SwiftUI

@MainActor
@Observable
final class SoundSession {
    private(set) var selectedMode: SoundMode?
    private(set) var status: PlaybackStatus = .idle

    var isPlaying: Bool { status.isAudible }

    private let engine: LoopingPlaybackEngine
    private let preferences: PlaybackPreferences
    private var commandTail: Task<Void, Never>?
    private let observerBag = NotificationObserverBag()

    init(engine: LoopingPlaybackEngine, preferences: PlaybackPreferences) {
        self.engine = engine
        self.preferences = preferences
        observeRuntimeEvents()
    }

    func prepare() {
        let resources = SoundModeCatalog.all.map(\.resource)
        let tempo = preferences.tempo
        let gain = preferences.intensity.rawValue

        enqueue { [engine] in
            await engine.warmup(resources: resources)
            await engine.applyRate(tempo)
            await engine.applyGain(gain)
        }
    }

    func select(_ mode: SoundMode) {
        selectedMode = mode
        guard isPlaying else { return }
        play(mode)
    }

    func togglePower() {
        if isPlaying {
            stop()
        } else if let selectedMode {
            play(selectedMode)
        }
    }

    func play(_ mode: SoundMode) {
        selectedMode = mode
        status = .playing(mode.id)
        let tempo = preferences.tempo
        let gain = preferences.intensity.rawValue

        enqueue { [engine] in
            await engine.applyRate(tempo)
            await engine.applyGain(gain)
            await engine.play(mode.resource)
        }
    }

    func stop() {
        status = .idle
        enqueue { [engine] in
            await engine.halt()
        }
    }

    func leaveScreen() {
        stop()
    }

    func syncLiveAudioParameters() {
        let tempo = preferences.tempo
        let gain = preferences.intensity.rawValue
        enqueue { [engine] in
            await engine.applyRate(tempo)
            await engine.applyGain(gain)
        }
    }

    func handleScenePhase(_ phase: ScenePhase, stopsOnInactive: Bool) {
        switch phase {
        case .background:
            stop()
        case .inactive:
            if stopsOnInactive {
                stop()
            }
        default:
            break
        }
    }

    private func observeRuntimeEvents() {
        let interruption = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleInterruption(notification)
            }
        }

        let reset = NotificationCenter.default.addObserver(
            forName: AVAudioSession.mediaServicesWereResetNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleMediaReset()
            }
        }

        observerBag.add(interruption)
        observerBag.add(reset)
    }

    private func handleInterruption(_ notification: Notification) {
        let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
        let type = typeValue.flatMap(AVAudioSession.InterruptionType.init(rawValue:))

        switch type {
        case .began:
            if case .playing(let id) = status {
                status = .interrupted(id)
                enqueue { [engine] in
                    await engine.halt(keepEngineRunning: true)
                }
            }
        case .ended:
            let optionsValue = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue ?? 0)
            if case .interrupted(let id) = status,
               options.contains(.shouldResume),
               let mode = SoundModeCatalog.mode(with: id) {
                play(mode)
            } else if case .interrupted = status {
                status = .idle
            }
        default:
            break
        }
    }

    private func handleMediaReset() {
        let restore = selectedMode
        let wasPlaying: Bool
        switch status {
        case .playing, .interrupted:
            wasPlaying = true
        case .idle:
            wasPlaying = false
        }

        enqueue { [engine] in
            await engine.rebuildIfNeeded()
        } then: { [weak self] in
            guard let self, wasPlaying, let restore else { return }
            self.play(restore)
        }
    }

    private func enqueue(
        _ work: @escaping () async -> Void,
        then completion: (() -> Void)? = nil
    ) {
        commandTail = Task { [commandTail] in
            _ = await commandTail?.value
            await work()
            if let completion {
                await MainActor.run {
                    completion()
                }
            }
        }
    }
}

private final class NotificationObserverBag: @unchecked Sendable {
    private var tokens: [NSObjectProtocol] = []

    func add(_ token: NSObjectProtocol) {
        tokens.append(token)
    }

    deinit {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
