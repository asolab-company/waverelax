import CoreHaptics
import Foundation

@MainActor
@Observable
final class SessionHaptics {
    let isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private(set) var errorMessage: String?
    private var engine: CHHapticEngine?
    private var player: (any CHHapticAdvancedPatternPlayer)?

    func play(mode: SoundModeID, intensity: Float, tempo: Float) {
        stop()
        guard isSupported else { return }
        do {
            let engine = try preparedEngine()
            try engine.start()
            let beats = rhythm(for: mode)
            let step = 0.22 / Double(max(0.25, tempo))
            let events = beats.enumerated().map { index, strength in
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * strength),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: mode == .drill ? 0.9 : 0.35)
                    ],
                    relativeTime: Double(index) * step,
                    duration: step * 0.65
                )
            }
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            player.loopEnabled = true
            player.loopEnd = Double(beats.count) * step
            self.player = player
            try player.start(atTime: CHHapticTimeImmediate)
            errorMessage = nil
        } catch {
            errorMessage = "Vibrations are temporarily unavailable. Try starting the session again."
        }
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        player = nil
    }

    private func preparedEngine() throws -> CHHapticEngine {
        if let engine { return engine }
        let engine = try CHHapticEngine()
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak self] in
            Task { @MainActor [weak self] in
                self?.player = nil
                self?.engine = nil
            }
        }
        engine.stoppedHandler = { [weak self] _ in
            Task { @MainActor [weak self] in self?.player = nil }
        }
        self.engine = engine
        return engine
    }

    private func rhythm(for mode: SoundModeID) -> [Float] {
        switch mode {
        case .beat: [1, 0.3, 0.7, 0.3]
        case .draft: [0.2, 0.4, 0.6, 0.4]
        case .tempest: [0.6, 1, 0.4, 0.9, 0.3, 1]
        case .surge: [0.25, 0.5, 0.75, 1, 0.75, 0.5]
        case .ripple: [0.8, 0.6, 0.4, 0.2]
        case .outburst: [1, 0.9, 0.2, 0.2, 0.6, 1]
        case .cosmos: [0.3, 0.7, 0.2, 0.5, 0.9, 0.4]
        case .meteoroid: [0.2, 0.4, 1, 0.3]
        case .vessel: [0.8, 0.8, 0.3, 0.3]
        case .lyre: [0.3, 0.5, 0.8, 0.5, 0.3, 0.6]
        case .percussion: [1, 0.2, 0.7, 0.7, 0.2, 0.9]
        case .drill: [1, 1, 1, 1]
        }
    }
}
