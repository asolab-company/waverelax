import Foundation
import StoreKit

@MainActor
final class SubscriptionAnalyticsService {
    static let shared = SubscriptionAnalyticsService()
    private let reportedKey = "wavevibro.storekit.reportedTransactions"
    private var syncTask: Task<Void, Never>?
    private var reported: Set<String>

    private init() {
        reported = Set(UserDefaults.standard.stringArray(forKey: reportedKey) ?? [])
    }

    func start() {
        guard syncTask == nil else { return }
        syncTask = Task {
            defer { syncTask = nil }
            for await result in StoreKit.Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else { continue }
                report(transaction)
            }
        }
    }

    func report(_ transaction: StoreKit.Transaction) {
        let id = String(transaction.id)
        guard AppConfiguration.StoreKit.premiumProductIDs.contains(transaction.productID),
              !reported.contains(id)
        else { return }
        guard AnalyticsService.shared.track("Subscription Transaction", properties: [
            "product_id": transaction.productID,
            "transaction_id": id,
            "original_transaction_id": String(transaction.originalID),
        ]) else { return }
        reported.insert(id)
        UserDefaults.standard.set(Array(reported), forKey: reportedKey)
    }
}
