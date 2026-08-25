import SwiftUI

enum AppTab: Hashable {
    case library
    case studio
    case settings

    var title: String {
        switch self {
        case .library:
            return "Library"
        case .studio:
            return "Studio"
        case .settings:
            return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .library:
            return "ic_wand"
        case .studio:
            return "ic_waves"
        case .settings:
            return "ic_settings"
        }
    }
}
