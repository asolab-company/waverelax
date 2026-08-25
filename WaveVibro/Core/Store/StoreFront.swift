import Foundation
import StoreKit

enum PurchaseOutcome {
    case success
    case cancelled
    case pending
    case failed(String)
}

@MainActor
@Observable
final class StoreFront {
    static let shared = StoreFront()

    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isSubscribed = false
    private(set) var isLoadingProducts = false
    private(set) var hasLoadedEntitlements = false

    private let productIDs: Set<String> = [ProductIdentity.weekly, ProductIdentity.yearly]

    private init() {
        Task {
            observeTransactionUpdates()
            await fetchProducts()
            await refreshEntitlements()
        }
    }

    var weeklyProduct: Product? {
        products.first { $0.id == ProductIdentity.weekly }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == ProductIdentity.yearly }
    }

    func isUnlocked(_ mode: SoundMode) -> Bool {
        !mode.requiresPremium || isSubscribed
    }

    func isUnlocked(_ grade: IntensityGrade) -> Bool {
        !grade.requiresPremium || isSubscribed
    }

    func fetchProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Array(productIDs))
            products = loaded.sorted { $0.price < $1.price }
        } catch {}
    }

    func purchase(product: Product) async -> PurchaseOutcome {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    return .success
                case .unverified(_, let error):
                    return .failed(error.localizedDescription)
                }
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("Unknown purchase result")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {}
    }

    func refreshEntitlements() async {
        var owned = Set<String>()
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                owned.insert(transaction.productID)
            }
        }
        purchasedProductIDs = owned
        isSubscribed = await computeActiveSubscription()
        hasLoadedEntitlements = true
    }

    private func computeActiveSubscription() async -> Bool {
        for id in productIDs {
            if let latest = await Transaction.latest(for: id),
               case .verified(let transaction) = latest,
               transaction.revocationDate == nil,
               (transaction.expirationDate ?? .distantFuture) > Date() {
                return true
            }
        }
        return false
    }

    private func observeTransactionUpdates() {
        Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            }
        }
    }
}
