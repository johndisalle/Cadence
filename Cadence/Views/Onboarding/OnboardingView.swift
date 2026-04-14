import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0
    @State private var selectedStarters: Set<EventTemplate>

    /// The 3 starter templates pre-selected on screen 3.
    private static let starterTemplates: [EventTemplate] = [
        .oilChange,
        .changeHVACFilter,
        .haircut,
    ]

    init() {
        // Pre-select all 3 starters
        _selectedStarters = State(initialValue: Set(Self.starterTemplates))
    }

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            valuePropPage.tag(1)
            startersPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            ZStack {
                Circle()
                    .fill(CadenceTheme.teal.opacity(0.08))
                    .frame(width: 200, height: 200)
                Circle()
                    .fill(CadenceTheme.teal.opacity(0.05))
                    .frame(width: 260, height: 260)
                Image(systemName: "water.waves")
                    .font(.system(size: 64))
                    .foregroundStyle(CadenceTheme.teal)
            }

            VStack(spacing: CadenceTheme.spacingSM) {
                Text("Cadence")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(CadenceTheme.textPrimary)

                Text("Remember everything. Stress about nothing.")
                    .font(.title3)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(CadenceTheme.teal))
            }
            .padding(.horizontal, CadenceTheme.spacingXL)
            .padding(.bottom, CadenceTheme.spacingXL)
        }
        .padding(CadenceTheme.spacingLG)
    }

    // MARK: - Page 2: Value Prop

    private var valuePropPage: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(CadenceTheme.teal)
                .padding(.bottom, CadenceTheme.spacingMD)

            VStack(spacing: CadenceTheme.spacingMD) {
                Text("Track things you do,\nbut not every day.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Cadence learns YOUR rhythm — when did you last change your oil? Water plants? Get a haircut? Cadence remembers so you don't have to.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, CadenceTheme.spacingMD)
            }

            Text("100% private. No accounts. No cloud.")
                .font(.footnote)
                .foregroundStyle(CadenceTheme.textTertiary)
                .padding(.top, CadenceTheme.spacingSM)

            Spacer()

            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(CadenceTheme.teal))
            }
            .padding(.horizontal, CadenceTheme.spacingXL)
            .padding(.bottom, CadenceTheme.spacingXL)
        }
        .padding(CadenceTheme.spacingLG)
    }

    // MARK: - Page 3: Three Starter Events

    private var startersPage: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            VStack(spacing: CadenceTheme.spacingSM) {
                Text("Let's start with 3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CadenceTheme.textPrimary)

                Text("Tap any to remove. You can add more anytime.")
                    .font(.subheadline)
                    .foregroundStyle(CadenceTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, CadenceTheme.spacingXL)

            VStack(spacing: CadenceTheme.spacingMD) {
                ForEach(Self.starterTemplates) { template in
                    starterCard(template: template)
                }
            }
            .padding(.horizontal, CadenceTheme.spacingMD)

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Start Tracking")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(CadenceTheme.teal))
            }
            .padding(.horizontal, CadenceTheme.spacingXL)
            .padding(.bottom, CadenceTheme.spacingXL)
        }
        .padding(CadenceTheme.spacingLG)
    }

    private func starterCard(template: EventTemplate) -> some View {
        let isSelected = selectedStarters.contains(template)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    selectedStarters.remove(template)
                } else {
                    selectedStarters.insert(template)
                }
            }
        } label: {
            HStack(spacing: CadenceTheme.spacingMD) {
                Image(systemName: template.emoji)
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: template.accentColorHex))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(Color(hex: template.accentColorHex).opacity(isSelected ? 0.15 : 0.08))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Text(template.intervalDescription.capitalized)
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
                RoundedRectangle(cornerRadius: CadenceTheme.cardCornerRadius)
                    .fill(CadenceTheme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: CadenceTheme.cardCornerRadius)
                            .strokeBorder(isSelected ? CadenceTheme.teal : .clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
            )
            .opacity(isSelected ? 1.0 : 0.6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func completeOnboarding() {
        // Create selected starter events
        for template in selectedStarters {
            let event = Event(
                name: template.name,
                emoji: template.emoji,
                accentColorHex: template.accentColorHex,
                category: template.category
            )
            modelContext.insert(event)
        }

        requestNotificationPermission()
        hasCompletedOnboarding = true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}
