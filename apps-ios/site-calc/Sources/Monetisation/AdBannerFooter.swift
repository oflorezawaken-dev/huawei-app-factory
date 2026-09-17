import SwiftUI

/// The one banner placement, added individually to the three screens that are
/// allowed to carry it (S008 Jobs, S009 Job Detail, S011 Settings) -- never a
/// blanket banner beneath the whole TabView, since that would leak onto the
/// calculator and solver tabs which must never show an ad in any state.
struct AdBannerFooter: View {
    @Environment(RemoveAdsStore.self) private var store

    var body: some View {
        if !store.adsRemoved && !UITestMode.isActive {
            BannerAdView()
                .frame(height: 50)
                .accessibilityIdentifier("ad.banner")
        }
    }
}
