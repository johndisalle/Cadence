import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0
    @State private var selectedTemplates: Set<EventTemplate> = []
    @State private var showAllTemplates = false

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            quickStartPage.tag(1)
            confirmationPage.tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .sheet(isPresented: $showAllTemplates) {
            allTemplatesSheet
        }
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
            }

            Text("100% private. No accounts. No cloud. Just you and your rhythm.")
                .font(.footnote)
                .foregroundStyle(CadenceTheme.textTertiary)
                .padding(.top, CadenceTheme.spacingXS)

            Text("Plants die. Oil changes get forgotten. Haircuts get pushed back. Cadence keeps track so you don't have to.")
                .font(.footnote)
                .foregroundStyle(CadenceTheme.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

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

    // MARK: - Page 2: Quick Start Packs

    private var quickStartPage: some View {
        ScrollView {
            VStack(spacing: CadenceTheme.spacingLG) {
                VStack(spacing: CadenceTheme.spacingSM) {
                    Text("Choose a starting point")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CadenceTheme.textPrimary)

                    Text("Pick one or more packs, or build your own")
                        .font(.subheadline)
                        .foregroundStyle(CadenceTheme.textSecondary)
                }
                .padding(.top, CadenceTheme.spacingXL)

                VStack(spacing: CadenceTheme.spacingMD) {
                    ForEach(EventTemplate.quickStartPacks) { pack in
                        quickStartCard(pack: pack)
                    }
                }
                .padding(.horizontal, CadenceTheme.spacingMD)

                Button {
                    showAllTemplates = true
                } label: {
                    Label("Browse All Templates", systemImage: "square.grid.2x2")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CadenceTheme.teal)
                }
                .padding(.top, CadenceTheme.spacingSM)

                Button {
                    withAnimation { currentPage = 2 }
                } label: {
                    Text("Or start from scratch")
                        .font(.footnote)
                        .foregroundStyle(CadenceTheme.textTertiary)
                }
                .padding(.bottom, CadenceTheme.spacingSM)

                if !selectedTemplates.isEmpty {
                    Button {
                        withAnimation { currentPage = 2 }
                    } label: {
                        Text("Continue with \(selectedTemplates.count) events")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Capsule().fill(CadenceTheme.teal))
                    }
                    .padding(.horizontal, CadenceTheme.spacingXL)
                }

                Spacer(minLength: CadenceTheme.spacingXL)
            }
        }
    }

    private func quickStartCard(pack: QuickStartPack) -> some View {
        let isSelected = pack.templates.allSatisfy { selectedTemplates.contains($0) }

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isSelected {
                    pack.templates.forEach { selectedTemplates.remove($0) }
                } else {
                    pack.templates.forEach { selectedTemplates.insert($0) }
                }
            }
        } label: {
            HStack(spacing: CadenceTheme.spacingMD) {
                Image(systemName: pack.emoji)
                    .font(.system(size: 28))
                    .foregroundStyle(CadenceTheme.teal)

                VStack(alignment: .leading, spacing: 2) {
                    Text(pack.name)
                        .font(.headline)
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Text(pack.description)
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textSecondary)
                    Text("\(pack.count) events")
                        .font(.caption2)
                        .foregroundStyle(CadenceTheme.textTertiary)
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
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page 3: Confirmation

    private var confirmationPage: some View {
        VStack(spacing: CadenceTheme.spacingLG) {
            Spacer()

            if selectedTemplates.isEmpty {
                VStack(spacing: CadenceTheme.spacingSM) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 48))
                        .foregroundStyle(CadenceTheme.teal)
                    Text("Your rhythm starts now")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CadenceTheme.textPrimary)
                    Text("The best time to start tracking was yesterday.\nThe second best time is right now.")
                        .font(.subheadline)
                        .foregroundStyle(CadenceTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: CadenceTheme.spacingMD) {
                    Text("\(selectedTemplates.count) rhythms, ready to flow")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CadenceTheme.textPrimary)

                    selectedEventsFlow

                    Text("Tip: Log your first event right away — it feels great.")
                        .font(.footnote)
                        .foregroundStyle(CadenceTheme.textSecondary)
                        .padding(.top, CadenceTheme.spacingSM)
                }
            }

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Let's Go!")
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

    private var selectedEventsFlow: some View {
        let templates = Array(selectedTemplates).sorted { $0.name < $1.name }
        return FlowLayout(spacing: CadenceTheme.spacingSM) {
            ForEach(templates) { template in
                HStack(spacing: 4) {
                    Image(systemName: template.emoji)
                        .font(.caption)
                        .foregroundStyle(Color(hex: template.accentColorHex))
                    Text(template.name)
                        .font(.caption)
                        .foregroundStyle(CadenceTheme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(hex: template.accentColorHex).opacity(0.15))
                )
            }
        }
        .padding(.horizontal, CadenceTheme.spacingMD)
    }

    // MARK: - All Templates Sheet

    private var allTemplatesSheet: some View {
        NavigationStack {
            TemplatePickerView(selectedTemplates: $selectedTemplates)
                .navigationTitle("All Templates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showAllTemplates = false
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        for template in selectedTemplates {
            let event = Event(
                name: template.name,
                emoji: template.emoji,
                accentColorHex: template.accentColorHex,
                category: template.category
            )
            modelContext.insert(event)
        }

        hasCompletedOnboarding = true

        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { _, _ in }
    }
}

// MARK: - Template Picker View (Sheet)

struct TemplatePickerView: View {
    @Binding var selectedTemplates: Set<EventTemplate>
    @State private var searchText = ""

    private var groupedTemplates: [(String, [EventTemplate])] {
        let filtered: [EventTemplate]
        if searchText.isEmpty {
            filtered = EventTemplate.allTemplates
        } else {
            filtered = EventTemplate.allTemplates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        let grouped = Dictionary(grouping: filtered) { $0.category.displayName }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            ForEach(groupedTemplates, id: \.0) { category, templates in
                Section(category) {
                    ForEach(templates) { template in
                        templateRow(template)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search templates")
    }

    private func templateRow(_ template: EventTemplate) -> some View {
        let isSelected = selectedTemplates.contains(template)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isSelected {
                    selectedTemplates.remove(template)
                } else {
                    selectedTemplates.insert(template)
                }
            }
        } label: {
            HStack(spacing: CadenceTheme.spacingSM) {
                Image(systemName: template.emoji)
                    .font(.title3)
                    .foregroundStyle(Color(hex: template.accentColorHex))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.body)
                        .foregroundStyle(CadenceTheme.textPrimary)
                    HStack(spacing: CadenceTheme.spacingXS) {
                        Text(template.subtitle)
                        Text("·")
                        Text(template.intervalDescription)
                    }
                    .font(.caption)
                    .foregroundStyle(CadenceTheme.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(CadenceTheme.teal)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .modelContainer(for: [Event.self, LogEntry.self], inMemory: true)
}

#Preview("Template Picker") {
    NavigationStack {
        TemplatePickerView(selectedTemplates: .constant([.exercise, .waterPlants]))
    }
}
