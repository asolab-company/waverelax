import Foundation

enum LaunchStage {
    case splash
    case onboarding
    case nativePaywall
    case webOnboarding
    case webPaywall
    case shell
}

@MainActor
enum LaunchDestinationResolver {
    static func resolve(store: StoreFront) async -> LaunchStage {
        OnboardingStore.prepareJourneyState()
        async let offers: Void = store.fetchProducts()
        await store.refreshEntitlements()
        await offers
        if store.isSubscribed {
            OnboardingStore.markJourneyCompleted()
            return .shell
        }
        if OnboardingStore.hasCompletedJourney { return .shell }
        if store.useWebPaywall { return .webOnboarding }
        return nativeDestination
    }
    static var nativeDestination: LaunchStage {
        OnboardingStore.hasCompletedOnboarding ? .nativePaywall : .onboarding
    }
}
