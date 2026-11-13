import AppsFlyerLib
import Foundation
import StoreKit

@MainActor
final class SubscriptionAnalyticsService {
    static let shared = SubscriptionAnalyticsService()
    private let reportedKey = "wavevibro.storekit.reportedTransactions"
    private let attributionReportedKey = "wavevibro.appsflyer.reportedTransactions"
    private let pendingKey = "wavevibro.appsflyer.pendingEvents"
    private var syncTask: Task<Void, Never>?
    private var reported: Set<String>
    private var attributionReported: Set<String>
    private var pending: [String: String]
    private var sending = Set<String>()

    private init() {
        reported = Set(UserDefaults.standard.stringArray(forKey: reportedKey) ?? [])
        attributionReported = Set(UserDefaults.standard.stringArray(forKey: attributionReportedKey) ?? [])
        pending = UserDefaults.standard.dictionary(forKey: pendingKey) as? [String: String] ?? [:]
    }

    func start() {
        flushAttributionEvents()
        guard syncTask == nil else { return }
        syncTask = Task {
            defer { syncTask = nil }
            for await result in StoreKit.Transaction.currentEntitlements { report(result) }
        }
    }

    func report(_ verification: VerificationResult<StoreKit.Transaction>, recordsConversion: Bool = false) {
        guard case .verified(let transaction) = verification,
              AppConfiguration.StoreKit.premiumProductIDs.contains(transaction.productID),
              transaction.revocationDate == nil, !transaction.isUpgraded,
              transaction.ownershipType == .purchased
        else { return }
        let id = String(transaction.id)
        Task { await AdaptyService.shared.report(verification) }
        guard transaction.environment != .xcode else { return }
        if !reported.contains(id), AnalyticsService.shared.track("Subscription Transaction", properties: [
            "product_id": transaction.productID,
            "transaction_id": id,
            "original_transaction_id": String(transaction.originalID),
            "is_trial": transaction.offer?.paymentMode == .freeTrial
        ]) {
            reported.insert(id)
            UserDefaults.standard.set(Array(reported), forKey: reportedKey)
        }
        if recordsConversion, !attributionReported.contains(id), pending[id] == nil {
            pending[id] = transaction.offer?.paymentMode == .freeTrial ? AFEventStartTrial : AFEventSubscribe
            UserDefaults.standard.set(pending, forKey: pendingKey)
        }
        flushAttributionEvents()
    }

    func flushAttributionEvents() {
        guard AttributionService.shared.canLogEvents else { return }
        for (id, eventName) in pending where !sending.contains(id) {
            sending.insert(id)
            AppsFlyerLib.shared().logEvent(name: eventName, values: nil) { [weak self] _, error in
                let succeeded = error == nil
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.sending.remove(id)
                    guard succeeded else { return }
                    self.attributionReported.insert(id)
                    self.pending.removeValue(forKey: id)
                    UserDefaults.standard.set(Array(self.attributionReported), forKey: self.attributionReportedKey)
                    UserDefaults.standard.set(self.pending, forKey: self.pendingKey)
                }
            }
        }
    }
}
