import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    let premiumManager = PremiumManager.shared

    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("infinity", "Unlimited Events", "Track everything — no limits"),
        ("waveform.path.ecg", "AI Rhythm Insights", "Weekly Cadence Pulse + smart suggestions"),
        ("person.2.fill", "Family Sharing", "Sync shared household tasks via iCloud"),
        ("doc.richtext", "PDF Export", "Beautiful summaries you can share"),
        ("bell.badge.fill", "Smart Reminders", "Notifications tuned to your rhythm"),
        ("chart.xyaxis.line", "Advanced Charts", "Deep interval analysis + trends"),
    ]

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
            selectedProduct = premiumManager.products.first { $0.id == PremiumManager.yearlyID }
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

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CadenceTheme.textPrimary)
                        Text(feature.subtitle)
                            .font(.caption)
                            .foregroundStyle(CadenceTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 12)
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
        VStack(spacing: CadenceTheme.spacingSM) {
            if premiumManager.isLoading {
                ProgressView()
                    .padding()
            } else if premiumManager.products.isEmpty {
                // Fallback when StoreKit products aren't configured yet
                fallbackPricing
            } else {
                ForEach(premiumManager.products, id: \.id) { product in
                    pricingCard(product: product)
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
                        Text("Continue")
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

    private func pricingCard(product: Product) -> some View {
        let isSelected = selectedProduct?.id == product.id
        let isYearly = product.id == PremiumManager.yearlyID

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProduct = product
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: CadenceTheme.spacingSM) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(CadenceTheme.textPrimary)

                        if isYearly {
                            Text("Best Value")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(CadenceTheme.teal))
                        }
                    }

                    Text(product.description)
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textSecondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundStyle(isSelected ? CadenceTheme.teal : CadenceTheme.textSecondary)
            }
            .padding(CadenceTheme.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(CadenceTheme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isSelected ? CadenceTheme.teal : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // Shown when StoreKit products aren't configured in App Store Connect yet
    private var fallbackPricing: some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            pricingPlaceholder(name: "Monthly", price: "$2.99/mo", description: "Billed monthly")
            pricingPlaceholder(name: "Yearly", price: "$19.99/yr", description: "Save 44% — best value", isBest: true)
            pricingPlaceholder(name: "Lifetime", price: "$49.99", description: "One-time purchase, forever")
        }
    }

    private func pricingPlaceholder(name: String, price: String, description: String, isBest: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: CadenceTheme.spacingSM) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CadenceTheme.textPrimary)
                    if isBest {
                        Text("Best Value")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(CadenceTheme.teal))
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            Spacer()
            Text(price)
                .font(.headline)
                .foregroundStyle(isBest ? CadenceTheme.teal : CadenceTheme.textSecondary)
        }
        .padding(CadenceTheme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(CadenceTheme.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isBest ? CadenceTheme.teal : .clear, lineWidth: 2)
                )
        )
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
