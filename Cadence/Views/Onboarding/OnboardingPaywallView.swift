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
        ("infinity", "Unlimited events"),
        ("waveform.path.ecg", "AI Rhythm Insights"),
        ("chart.xyaxis.line", "Advanced interval charts"),
        ("doc.richtext", "PDF export summaries"),
        ("person.2.fill", "Family Sharing sync"),
        ("bell.badge.fill", "Smart reminders"),
    ]

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

                        Text("Start your free 3-day trial")
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
                            Text("Start Free Trial")
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

                Button {
                    onContinue()
                } label: {
                    Text("Continue with free")
                        .font(.subheadline)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }

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

    // MARK: - Pricing

    private var pricingSection: some View {
        VStack(spacing: CadenceTheme.spacingSM) {
            if premiumManager.products.isEmpty {
                // Fallback when StoreKit products aren't configured
                pricingCard(
                    name: "Yearly",
                    detail: "3 days free, then $19.99/year",
                    isSelected: true,
                    isBest: true
                )
                pricingCard(
                    name: "Monthly",
                    detail: "$2.99/month",
                    isSelected: false,
                    isBest: false
                )
            } else {
                ForEach(premiumManager.products.filter { $0.id != PremiumManager.lifetimeID }, id: \.id) { product in
                    let isYearly = product.id == PremiumManager.yearlyID
                    let isSelected = selectedProduct?.id == product.id

                    Button {
                        selectedProduct = product
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 8) {
                                    Text(product.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    if isYearly {
                                        Text("Best Value")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(CadenceTheme.teal))
                                    }
                                }
                                if isYearly {
                                    Text("3 days free, then \(product.displayPrice)/year")
                                        .font(.caption)
                                        .foregroundStyle(CadenceTheme.textSecondary)
                                } else {
                                    Text("\(product.displayPrice)/month")
                                        .font(.caption)
                                        .foregroundStyle(CadenceTheme.textSecondary)
                                }
                            }
                            Spacer()
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isSelected ? CadenceTheme.teal : CadenceTheme.textTertiary)
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
            }
        }
    }

    private func pricingCard(name: String, detail: String, isSelected: Bool, isBest: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                    if isBest {
                        Text("Best Value")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(CadenceTheme.teal))
                    }
                }
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? CadenceTheme.teal : CadenceTheme.textTertiary)
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
