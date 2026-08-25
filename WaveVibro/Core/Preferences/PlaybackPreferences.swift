import Foundation

@MainActor
@Observable
final class PlaybackPreferences {
    var intensity: IntensityGrade {
        didSet { persist() }
    }

    var tempo: Float {
        didSet { persist() }
    }

    var onChange: (() -> Void)?

    private static let intensityKey = "playback_intensity"
    private static let tempoKey = "playback_tempo"
    private static let legacyIntensityKey = "vibration_intensity"
    private static let legacyTempoKey = "vibration_speed"

    init() {
        if let stored = UserDefaults.standard.object(forKey: Self.intensityKey) as? Float,
           let grade = IntensityGrade(rawValue: stored) {
            intensity = grade
        } else if let stored = UserDefaults.standard.object(forKey: Self.legacyIntensityKey) as? Float,
                  let grade = IntensityGrade(rawValue: stored) {
            intensity = grade
        } else {
            intensity = .easy
        }

        if let stored = UserDefaults.standard.object(forKey: Self.tempoKey) as? Float {
            tempo = min(max(stored, 0), TempoLimits.absoluteMaximum)
        } else if let stored = UserDefaults.standard.object(forKey: Self.legacyTempoKey) as? Float {
            tempo = min(max(stored, 0), TempoLimits.absoluteMaximum)
        } else {
            tempo = 0.5
        }
    }

    func clampTempo(hasPremiumAccess: Bool) {
        tempo = min(max(tempo, 0), TempoLimits.absoluteMaximum)
        guard !hasPremiumAccess else { return }
        tempo = min(tempo, TempoLimits.freeMaximumTempo)
    }

    private func persist() {
        UserDefaults.standard.set(intensity.rawValue, forKey: Self.intensityKey)
        UserDefaults.standard.set(tempo, forKey: Self.tempoKey)
        onChange?()
    }
}

enum TempoLimits {
    static let absoluteMaximum: Float = 2.0
    static let freeProgressCeiling: Float = 0.4

    static var freeMaximumTempo: Float {
        freeProgressCeiling * absoluteMaximum
    }
}
