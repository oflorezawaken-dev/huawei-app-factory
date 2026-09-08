import SwiftUI

/// Applied only to the four screens the spec allows a banner on (Price Book,
/// Item History, Stores, Stats). Every other screen simply never calls this,
/// so the ad container is fully absent there -- not hidden, not
/// zero-opacity, not present-but-disabled -- which is what the "container
/// must be absent" acceptance criterion checks for.
struct BannerAdFooter: ViewModifier {
    @Environment(RemoveAdsStore.self) private var store

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
            if AdsConfiguration.bannerEnabled && !store.adsRemoved && !UITestMode.isActive {
                BannerAdView()
                    .frame(height: 50)
                    .accessibilityIdentifier("ad.banner")
            }
        }
    }
}

extension View {
    /// Adds the shared adaptive anchored banner above the tab bar, inside the
    /// safe area, unless Remove Ads is owned or this is a UI test run.
    func pjBannerFooter() -> some View {
        modifier(BannerAdFooter())
    }
}
