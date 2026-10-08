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
    private(set) var isLoadingProducts = false
    private(set) var hasLoadedEntitlements = false
    private(set) var useWebPaywall = false
    private(set) var introEligibility: [String: Bool] = [:]
    var errorMessage: String?
    private var nativeExpiresAt: Date?
    private var webExpiresAt: Date?
    private var webVerifiedAt: Date?
    private var configurationCheckedAt: Date?
    private var productTask: Task<Void, Never>?
    private var webTask: Task<Void, Never>?
    private var transactionTask: Task<Void, Never>?
    private let productIDs = Set(AppConfiguration.StoreKit.premiumProductIDs)

    private init() {
        transactionTask = Task { [weak self] in
            for await update in Transaction.updates {
                guard let self, !Task.isCancelled else { return }
                if case .verified(let transaction) = update, self.productIDs.contains(transaction.productID) {
                    SubscriptionAnalyticsService.shared.report(transaction)
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }
    isolated deinit { transactionTask?.cancel() }

    var isSubscribed: Bool {
        let now = Date()
        return (nativeExpiresAt ?? .distantPast) > now || ((webExpiresAt ?? .distantPast) > now
            && now.timeIntervalSince(webVerifiedAt ?? .distantPast) < 300)
    }
    var weeklyProduct: Product? { products.first { $0.id == ProductIdentity.weekly } }
    var yearlyProduct: Product? { products.first { $0.id == ProductIdentity.yearly } }
    var hasRecentConfiguration: Bool { Date().timeIntervalSince(configurationCheckedAt ?? .distantPast) < 60 }
    func isUnlocked(_ mode: SoundMode) -> Bool { !mode.requiresPremium || isSubscribed }
    func isUnlocked(_ grade: IntensityGrade) -> Bool { !grade.requiresPremium || isSubscribed }

    func preparePaywall() async {
        async let offers: Void = fetchProducts()
        if !hasRecentConfiguration { await refreshWebSubscription() }
        await offers
    }
    func fetchProducts() async {
        if let productTask { await productTask.value; return }
        guard products.isEmpty else { return }
        let task = Task {
            isLoadingProducts = true
            errorMessage = nil
            defer { isLoadingProducts = false }
            do {
                products = try await Product.products(for: Array(productIDs))
                    .filter { $0.type == .autoRenewable && $0.subscription != nil }
                    .sorted { $0.price < $1.price }
                for product in products {
                    introEligibility[product.id] = await product.subscription?.isEligibleForIntroOffer ?? false
                }
                if products.isEmpty { errorMessage = "Subscriptions are currently unavailable. Please try again." }
            } catch { errorMessage = error.localizedDescription }
        }
        productTask = task
        await task.value
        productTask = nil
    }
    func refreshWebSubscription() async {
        if let webTask { await webTask.value; return }
        let task = Task {
            do {
                let state = try await WebSubscriptionClient.shared.refresh()
                useWebPaywall = state.useWebPaywall
                let fractional = ISO8601DateFormatter()
                fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                webExpiresAt = state.entitlement.active ? state.entitlement.expiresAt.flatMap {
                    fractional.date(from: $0) ?? ISO8601DateFormatter().date(from: $0)
                } : nil
                webVerifiedAt = Date()
            } catch { useWebPaywall = false }
            configurationCheckedAt = Date()
        }
        webTask = task
        await task.value
        webTask = nil
    }
    func refreshEntitlements() async {
        async let web: Void = refreshWebSubscription()
        var owned = Set<String>()
        var latestNativeExpiry: Date?
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  productIDs.contains(transaction.productID), transaction.revocationDate == nil,
                  !transaction.isUpgraded, (transaction.expirationDate ?? .distantPast) > Date() else { continue }
            owned.insert(transaction.productID)
            if let expiry = transaction.expirationDate, expiry > (latestNativeExpiry ?? .distantPast) { latestNativeExpiry = expiry }
            SubscriptionAnalyticsService.shared.report(transaction)
        }
        purchasedProductIDs = owned
        nativeExpiresAt = latestNativeExpiry
        await web
        hasLoadedEntitlements = true
        for product in products { introEligibility[product.id] = await product.subscription?.isEligibleForIntroOffer ?? false }
    }
    func purchase(product: Product) async -> PurchaseOutcome {
        await refreshEntitlements()
        guard !isSubscribed else { return .success }
        guard productIDs.contains(product.id), product.type == .autoRenewable,
              product.subscription != nil else { return .failed("This subscription is unavailable.") }
        AnalyticsService.shared.track("Purchase Started", properties: ["product_id": product.id])
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { throw URLError(.cannotParseResponse) }
                SubscriptionAnalyticsService.shared.report(transaction)
                await transaction.finish()
                await refreshEntitlements()
                guard isSubscribed else { return .pending }
                AnalyticsService.shared.track("Purchase Completed", properties: ["product_id": product.id])
                return .success
            case .userCancelled:
                AnalyticsService.shared.track("Purchase Cancelled", properties: ["product_id": product.id])
                return .cancelled
            case .pending:
                AnalyticsService.shared.track("Purchase Pending", properties: ["product_id": product.id])
                return .pending
            @unknown default: return .failed("Unknown purchase result")
            }
        } catch {
            AnalyticsService.shared.track("Purchase Failed", properties: ["reason": "storekit_error"])
            return .failed(error.localizedDescription)
        }
    }
    func restore() async {
        AnalyticsService.shared.track("Restore Started")
        errorMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isSubscribed { errorMessage = "No active App Store subscription was found. Use Restore web subscription for a website purchase." }
            AnalyticsService.shared.track("Restore Completed", properties: ["has_premium": isSubscribed])
        } catch {
            errorMessage = error.localizedDescription
            AnalyticsService.shared.track("Restore Failed")
        }
    }
    func priceLine(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else { return product.displayPrice }
        let recurring = "\(product.displayPrice) / \(periodText(period))"
        guard introEligibility[product.id] == true, let offer = product.subscription?.introductoryOffer else { return recurring }
        if offer.paymentMode == .freeTrial { return "\(periodText(offer.period)) free trial, then \(recurring)" }
        return "\(offer.displayPrice) for \(periodText(offer.period)), then \(recurring)"
    }
    private func periodText(_ period: Product.SubscriptionPeriod) -> String {
        let unit: String = switch period.unit {
        case .day: "day"
        case .week: "week"
        case .month: "month"
        case .year: "year"
        @unknown default: "period"
        }
        return period.value == 1 ? unit : "\(period.value) \(unit)s"
    }
}
