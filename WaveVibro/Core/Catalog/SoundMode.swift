import Foundation

struct SoundMode: Identifiable, Hashable, Sendable {
    let id: SoundModeID
    let title: String
    let iconName: String
    let resource: SoundResource
    let requiresPremium: Bool
}

enum SoundModeID: String, CaseIterable, Identifiable, Sendable {
    case beat
    case draft
    case tempest
    case surge
    case ripple
    case outburst
    case cosmos
    case meteoroid
    case vessel
    case lyre
    case percussion
    case drill

    var id: String { rawValue }
}
