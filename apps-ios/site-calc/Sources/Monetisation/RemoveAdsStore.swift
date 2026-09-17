import StoreKit

/// The one-time "remove ads" purchase, via StoreKit 2.
@Observable
@MainActor
final class RemoveAdsStore {
    private(set) var product: Product?
    private(set) var adsRemoved = false
    private(set) var purchaseFailed = false

    private var productID: String { AdsConfiguration.removeAdsProductID }

    func loadProduct() async {
        guard !productID.isEmpty else { return }
        product = try? await Product.products(for: [productID]).first
    }

    /// Re-reads the entitlement from StoreKit, which is the source of truth and
    /// survives reinstalls and device changes.
    func refreshEntitlement() async {
        guard !productID.isEmpty else { return }
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == productID {
                adsRemoved = true
                return
            }
        }
        adsRemoved = false
    }

    func purchase() async {
        purchaseFailed = false
        if product == nil { await loadProduct() }
        guard let product else {
            purchaseFailed = true
            return
        }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result, case .verified(let transaction) = verification {
                await transaction.finish()
                await refreshEntitlement()
            }
        } catch {
            purchaseFailed = true
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }
}
