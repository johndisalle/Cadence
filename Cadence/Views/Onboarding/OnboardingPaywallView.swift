import SwiftUI
import StoreKit

struct OnboardingPaywallView: View {
    let onContinue: () -> Void
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
    private var headerSubtitle: String {
        if selectedProduct?.id == PremiumManager.lifetimeID {
            return "One payment. Yours forever."
        } else if selectedProduct?.id == PremiumManager.yearlyID {
            return "Start your free 3-day trial"
        } else {
            return "Unlock everything in Cadence"
        }
    }

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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: CadenceTheme.spacingLG) {
                    // Header
                    VStack(spacing: CadenceTheme.spacingSM) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [CadenceTheme.sand, CadenceTheme.coral],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.top, 48)

                        Text("Unlock Cadence Pro")
                            .font(.title.weight(.bold))

                        Text(headerSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(CadenceTheme.textSecondary)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(features, id: \.title) { feature in
                            HStack(spacing: 14) {
                                Image(systemName: feature.icon)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(CadenceTheme.teal)
                                    .frame(width: 28)

                                Text(feature.title)
                                    .font(.body)
                                    .foregroundStyle(CadenceTheme.textPrimary)

                                Spacer()

                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(CadenceTheme.sage)
                            }
                        }
                    }
                    .padding(CadenceTheme.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: CadenceTheme.cardCornerRadius)
                            .fill(CadenceTheme.backgroundSecondary)
                    )
                    .padding(.horizontal, CadenceTheme.spacingMD)

                    // Pricing
                    pricingSection
                        .padding(.horizontal, CadenceTheme.spacingMD)
                }
            }

            // Bottom buttons
            VStack(spacing: 12) {
                Button {
                    Task { await handlePurchase() }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
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
                .padding(.horizontal, CadenceTheme.spacingLG)

                // TODO: Replace with real user testimonial once we have reviews.
                // Target format: short quote (<140 chars) + first name +
                // "Cadence user since [month]". Pull from App Store reviews
                // or direct user feedback.
                // TestimonialCard(quote: "...", name: "...", since: "...")

                Button {
                    Task { await premiumManager.restorePurchases() }
                } label: {
                    Text("Restore Purchases")
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }

                Text("Cancel anytime. No commitment.")
                    .font(.caption2)
                    .foregroundStyle(CadenceTheme.textTertiary)
                    .padding(.bottom, 8)
            }
            .padding(.top, 12)
            .background(CadenceTheme.backgroundPrimary)
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
            onContinue()
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

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: CadenceTheme.spacingMD) {
            if premiumManager.products.isEmpty {
                // Fallback when StoreKit products aren't configured yet.
                // Lifetime is the hero; yearly is secondary.
                pricingCard(
                    name: "Lifetime",
                    detail: "$59.99 · one-time purchase, yours forever",
                    isSelected: true,
                    isHero: true
                )
                pricingCard(
                    name: "Yearly",
                    detail: "3 days free, then $24.99/year",
                    isSelected: false,
                    isHero: false
                )
            } else {
                // Lifetime first (hero), then yearly. Monthly is filtered out.
                let visible = premiumManager.products
                    .filter { $0.id != PremiumManager.monthlyID }
                    .sorted { a, b in
                        // Lifetime always first
                        if a.id == PremiumManager.lifetimeID { return true }
                        if b.id == PremiumManager.lifetimeID { return false }
                        return a.price < b.price
                    }

                ForEach(visible, id: \.id) { product in
                    let isLifetime = product.id == PremiumManager.lifetimeID
                    let isSelected = selectedProduct?.id == product.id
                    let detail: String = {
                        if isLifetime {
                            return "\(product.displayPrice) · one-time purchase, yours forever"
                        } else {
                            return "3 days free, then \(product.displayPrice)/year"
                        }
                    }()

                    pricingCard(
                        name: product.displayName,
                        detail: detail,
                        isSelected: isSelected,
                        isHero: isLifetime
                    ) {
                        selectedProduct = product
                    }
                }
            }
        }
    }

    private func pricingCard(
        name: String,
        detail: String,
        isSelected: Bool,
        isHero: Bool,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
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
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? CadenceTheme.teal : CadenceTheme.textTertiary)
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
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        do {
            let success = try await premiumManager.purchase(product)
            if success {
                onContinue()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}

#Preview {
    OnboardingPaywallView {
        print("Continue tapped")
    }
}
