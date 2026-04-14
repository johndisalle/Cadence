import Foundation
import StoreKit

/// Manages Cadence Pro subscription state.
/// Uses StoreKit 2 for a clean, modern in-app purchase flow.
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    // Product IDs — configure these in App Store Connect
    static let monthlyID = "com.cadence.app.pro.monthly"
    static let yearlyID = "com.cadence.app.pro.yearly"
    static let lifetimeID = "com.cadence.app.pro.lifetimev2"

    var isPremium: Bool = false
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading: Bool = false

    // Free tier limits
    static let freeEventLimit = 8
    static let freeExportLimit = 1 // per month

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await checkEntitlements() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    @MainActor
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [
                Self.monthlyID,
                Self.yearlyID,
                Self.lifetimeID
            ])
            products.sort { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    @MainActor
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkEntitlements()
            return true
        case .userCancelled:
            return false
        case .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Restore

    @MainActor
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkEntitlements()
    }

    // MARK: - Entitlements

    @MainActor
    func checkEntitlements() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
        isPremium = !purchased.isEmpty
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = try? self.checkVerified(result) {
                    await transaction.finish()
                    await self.checkEntitlements()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Gating Helpers

    func canAddEvent(currentCount: Int) -> Bool {
        isPremium || currentCount < Self.freeEventLimit
    }

    func canExport() -> Bool {
        isPremium
    }

    func canUseFamilySharing() -> Bool {
        isPremium
    }

    func canUseInsights() -> Bool {
        isPremium
    }

    // MARK: - First Upsell Tracking
    //
    // The user sees the "first upsell" paywall at most once across the
    // entire app lifetime, triggered by whichever happens first:
    //   (a) their first successful log action, or
    //   (b) tapping + while at the upsellEventCountThreshold.
    // After that, the existing PaywallView entry points (Settings, Insights,
    // chart blur, hard cap at freeEventLimit) handle subsequent presentations.

    private static let hasShownFirstUpsellKey = "hasShownFirstUpsellPaywall"
    static let upsellEventCountThreshold = 5  // Show on the 6th event create attempt

    var hasShownFirstUpsell: Bool {
        get { UserDefaults.standard.bool(forKey: Self.hasShownFirstUpsellKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.hasShownFirstUpsellKey) }
    }

    /// Call AFTER a successful log action. Returns true if the first upsell
    /// should be presented now. Consumes the flag — subsequent calls return false.
    func shouldTriggerFirstUpsellAfterLog() -> Bool {
        guard !isPremium, !hasShownFirstUpsell else { return false }
        hasShownFirstUpsell = true
        return true
    }

    /// Call when the user taps + to add an event. Returns true if the first
    /// upsell should be presented BEFORE the AddEventView. Consumes the flag.
    func shouldTriggerFirstUpsellOnAdd(currentCount: Int) -> Bool {
        guard !isPremium, !hasShownFirstUpsell else { return false }
        guard currentCount >= Self.upsellEventCountThreshold else { return false }
        hasShownFirstUpsell = true
        return true
    }
}

enum StoreError: Error {
    case verificationFailed
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted after any successful log action (from card, detail, or intent).
    /// HomeView observes this to fire the first-upsell paywall if needed.
    static let cadenceDidLogEvent = Notification.Name("cadenceDidLogEvent")
}
