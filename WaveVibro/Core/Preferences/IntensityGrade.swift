import Foundation

enum IntensityGrade: Float, CaseIterable, Identifiable {
    case easy = 0.6
    case medium = 0.8
    case strong = 1.0

    var id: Self { self }

    var title: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .strong:
            return "Hard"
        }
    }

    var subtitle: String {
        switch self {
        case .easy:
            return "Soft"
        case .medium:
            return "Balanced"
        case .strong:
            return "Full"
        }
    }

    var requiresPremium: Bool {
        self != .easy
    }
}
