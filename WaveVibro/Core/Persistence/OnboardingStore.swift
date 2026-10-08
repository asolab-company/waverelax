import Foundation

enum OnboardingStore {
    private static let introKey = "onboarding_passed"
    private static let journeyKey = "wavevibro.journey.completed"

    static func prepareJourneyState() {
        if UserDefaults.standard.object(forKey: journeyKey) == nil {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: journeyKey)
        }
    }
    static var hasCompletedOnboarding: Bool { UserDefaults.standard.bool(forKey: introKey) }
    static var hasCompletedJourney: Bool { UserDefaults.standard.bool(forKey: journeyKey) }
    static func markCompleted() { UserDefaults.standard.set(true, forKey: introKey) }
    static func markJourneyCompleted() {
        markCompleted()
        UserDefaults.standard.set(true, forKey: journeyKey)
    }
}
