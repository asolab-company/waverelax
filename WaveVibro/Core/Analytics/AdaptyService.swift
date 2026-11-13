import Adapty
import AppsFlyerLib
import Foundation
import StoreKit

@MainActor
final class AdaptyService {
    static let shared = AdaptyService()
    private var activationTask: Task<Bool, Never>?
    private var isActivated = false
    private var reported = Set(UserDefaults.standard.stringArray(forKey: "wavevibro.adapty.transactions") ?? [])
    private var reporting = Set<String>()

    private init() {}

    func configure() async -> Bool {
        if isActivated { return true }
        if let activationTask { return await activationTask.value }
        let task = Task { () -> Bool in
            guard !AppConfiguration.Analytics.adaptyAPIKey.isEmpty else { return false }
            do {
                let configuration = AdaptyConfiguration.builder(withAPIKey: AppConfiguration.Analytics.adaptyAPIKey)
                    .with(observerMode: true)
                    .with(logLevel: .error)
                    .build()
                try await Adapty.activate(with: configuration)
                isActivated = true
                return true
            } catch {
                return false
            }
        }
        activationTask = task
        let result = await task.value
        activationTask = nil
        return result
    }

    func syncIdentifiers() async {
        guard await configure() else { return }
        do {
            if let deviceID = AnalyticsService.shared.deviceID {
                try await Adapty.setIntegrationIdentifier(.amplitudeDeviceId(deviceID))
            }
            let appsFlyerID = AppsFlyerLib.shared().getAppsFlyerUID()
            if !appsFlyerID.isEmpty {
                try await Adapty.setIntegrationIdentifier(.appsflyerId(appsFlyerID))
            }
        } catch {
        }
    }

    func report(_ verification: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let transaction) = verification else { return }
        let id = String(transaction.id)
        guard !reported.contains(id), reporting.insert(id).inserted else { return }
        defer { reporting.remove(id) }
        guard await configure() else { return }
        do {
            try await Adapty.reportTransaction(verification)
            reported.insert(id)
            UserDefaults.standard.set(Array(reported), forKey: "wavevibro.adapty.transactions")
        } catch {
        }
    }
}
