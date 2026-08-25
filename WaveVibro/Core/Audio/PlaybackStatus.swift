import Foundation

enum PlaybackStatus: Equatable, Sendable {
    case idle
    case playing(SoundModeID)
    case interrupted(SoundModeID)

    var activeModeID: SoundModeID? {
        switch self {
        case .idle:
            return nil
        case .playing(let id), .interrupted(let id):
            return id
        }
    }

    var isAudible: Bool {
        if case .playing = self {
            return true
        }
        return false
    }
}
