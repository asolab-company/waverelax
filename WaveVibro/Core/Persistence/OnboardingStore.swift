import Foundation

enum OnboardingStore {
    private static let key = "onboarding_passed"

    static var hasCompletedOnboarding: Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
