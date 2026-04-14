import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let premiumManager = PremiumManager.shared

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let features: [(icon: String, title: String)] = [
        ("infinity", "Unlimited events (free: 8)"),
        ("waveform.path.ecg", "AI Rhythm Insights with weekly Pulse score"),
        ("chart.xyaxis.line", "Beautiful interval charts and trend analysis"),
        ("doc.richtext", "PDF export — share with family or landlords"),
        ("person.2.fill", "Family Sharing via iCloud"),
        ("bell.badge.fill", "Smart reminders tuned to your rhythm"),
    ]

    // Dynamic copy based on the currently selected tier.
    private var ctaButtonLabel: String {
        if selectedProduct?.id == PremiumManager.lifetimeID {
            return "Get Lifetime Access"
        } else if selectedProduct?.id == PremiumManager.yearlyID {
            return "Start Free Trial"
        } else {
            return "Continue"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: CadenceTheme.spacingLG) {
                headerSection
                featuresSection
                pricingSection
                legalSection
            }
            .padding(.horizontal, CadenceTheme.spacingMD)
            .padding(.bottom, CadenceTheme.spacingXL)
        }
        .background(CadenceTheme.backgroundPrimary)
        .overlay(alignment: .topTrailing) {
            closeButton
                .padding(.top, 16)
                .padding(.trailing, 16)
        }
        .task {
            await premiumManager.loadProducts()
            // Default to lifetime (hero), fall back to yearly, then first available.
            selectedProduct = premiumManager.products.first { $0.id == PremiumManager.lifetimeID }
                ?? premiumManager.products.first { $0.id == PremiumManager.yearlyID }
                ?? premiumManager.products.first
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color(.tertiarySystemFill))
                )
        }
        .accessibilityLabel("Close")
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(
                    LinearGradient(
                        colors: [CadenceTheme.sand, CadenceTheme.coral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, CadenceTheme.spacingLG)

            Text("Cadence Pro")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(CadenceTheme.textPrimary)

            Text("Unlock the full rhythm of life")
                .font(.subheadline)
                .foregroundStyle(CadenceTheme.textSecondary)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 0) {
            ForEach(features, id: \.title) { feature in
                HStack(spacing: CadenceTheme.spacingMD) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(CadenceTheme.teal)
                        .frame(width: 36)

                    Text(feature.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CadenceTheme.textPrimary)

                    Spacer()
                }
                .padding(.vertical, 14)
                .padding(.horizontal, CadenceTheme.cardPadding)

                if feature.title != features.last?.title {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: CadenceTheme.cardCornerRadius)
                .fill(CadenceTheme.backgroundSecondary)
        )
    }

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: CadenceTheme.spacingMD) {
            if premiumManager.isLoading {
                ProgressView()
                    .padding()
            } else if premiumManager.products.isEmpty {
                // Fallback when StoreKit products aren't configured yet
                fallbackPricing
            } else {
                // Lifetime first (hero), then yearly. Monthly is filtered
                // out of the UI; legacy monthly subscribers still have Pro
                // via checkEntitlements().
                let visible = premiumManager.products
                    .filter { $0.id != PremiumManager.monthlyID }
                    .sorted { a, b in
                        if a.id == PremiumManager.lifetimeID { return true }
                        if b.id == PremiumManager.lifetimeID { return false }
                        return a.price < b.price
                    }

                ForEach(visible, id: \.id) { product in
                    let isHero = product.id == PremiumManager.lifetimeID
                    pricingCard(product: product, isHero: isHero)
                }
            }

            // Purchase button
            Button {
                Task { await handlePurchase() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(ctaButtonLabel)
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule().fill(
                        LinearGradient(
                            colors: [CadenceTheme.teal, CadenceTheme.sage],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                )
            }
            .disabled(isPurchasing)
            .padding(.top, CadenceTheme.spacingSM)

            // TODO: Replace with real user testimonial once we have reviews.
            // Target format: short quote (<140 chars) + first name +
            // "Cadence user since [month]". Pull from App Store reviews
            // or direct user feedback.
            // TestimonialCard(quote: "...", name: "...", since: "...")

            // Restore
            Button {
                Task { await premiumManager.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.footnote)
                    .foregroundStyle(CadenceTheme.textTertiary)
            }
        }
    }

    private func pricingCard(product: Product, isHero: Bool) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let detail: String = {
            if isHero {
                return "One-time purchase, yours forever"
            } else if product.id == PremiumManager.yearlyID {
                return "3 days free, then billed annually"
            } else {
                return product.description
            }
        }()

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProduct = product
            }
        } label: {
            heroStyledCardContent(
                name: product.displayName,
                price: product.displayPrice,
                detail: detail,
                isSelected: isSelected,
                isHero: isHero
            )
        }
        .buttonStyle(.plain)
    }

    // Shown when StoreKit products aren't configured in App Store Connect yet
    private var fallbackPricing: some View {
        VStack(spacing: CadenceTheme.spacingMD) {
            pricingPlaceholder(
                name: "Lifetime",
                price: "$59.99",
                description: "One-time purchase, yours forever",
                isHero: true
            )
            pricingPlaceholder(
                name: "Yearly",
                price: "$24.99/yr",
                description: "3 days free, then billed annually",
                isHero: false
            )
        }
    }

    private func pricingPlaceholder(name: String, price: String, description: String, isHero: Bool) -> some View {
        heroStyledCardContent(
            name: name,
            price: price,
            detail: description,
            isSelected: isHero,
            isHero: isHero
        )
    }

    // Shared card renderer used by both the dynamic and fallback pricing paths.
    // Handles hero styling (larger padding, teal border, shadow, badge overlay)
    // and standard styling (selectable border only).
    private func heroStyledCardContent(
        name: String,
        price: String,
        detail: String,
        isSelected: Bool,
        isHero: Bool
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(isHero ? .title3.weight(.bold) : .subheadline.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textPrimary)
                Text(detail)
                    .font(isHero ? .subheadline : .caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            Spacer()
            Text(price)
                .font(isHero ? .title3.weight(.bold) : .headline)
                .foregroundStyle(isSelected ? CadenceTheme.teal : CadenceTheme.textSecondary)
        }
        .padding(.horizontal, CadenceTheme.cardPadding)
        .padding(.vertical, isHero ? 22 : CadenceTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(CadenceTheme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            isHero ? CadenceTheme.teal : (isSelected ? CadenceTheme.teal : .clear),
                            lineWidth: isHero ? 3 : 2
                        )
                )
                .shadow(
                    color: isHero ? CadenceTheme.teal.opacity(0.25) : .clear,
                    radius: isHero ? 10 : 0,
                    y: isHero ? 4 : 0
                )
        )
        .overlay(alignment: .topTrailing) {
            if isHero {
                Text("BEST VALUE · ONE PAYMENT, YOURS FOREVER")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(CadenceTheme.teal))
                    .offset(x: -12, y: -10)
            }
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 4) {
            Text("Payment will be charged to your Apple ID. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(CadenceTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, CadenceTheme.spacingSM)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        do {
            let success = try await premiumManager.purchase(product)
            if success {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

#Preview {
    PaywallView()
}
