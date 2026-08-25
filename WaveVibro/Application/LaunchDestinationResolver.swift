import Foundation

enum LaunchStage {
    case splash
    case onboarding
    case shell
}

@MainActor
enum LaunchDestinationResolver {
    static func resolve(store: StoreFront) async -> LaunchStage {
        await store.refreshEntitlements()

        guard OnboardingStore.hasCompletedOnboarding else {
            return .onboarding
        }

        return .shell
    }
}
