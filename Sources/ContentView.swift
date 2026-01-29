import SwiftUI

struct ContentView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @State private var companies: [Company] = []
    @State private var selectedCompany: Company?
    @State private var ideas: [ContentIdea] = []
    @State private var selectedIdea: ContentIdea?
    @State private var customTopic = ""
    @State private var tone: Tone = .professional
    @State private var generateImages = false
    @State private var imageStyle: ImageStyle = .photo
    @State private var variations = 1
    @State private var isLoadingCompanies = true
    @State private var isLoadingIdeas = false
    @State private var isGenerating = false
    @State private var apiStatus = "Checking..."
    @State private var errorMessage: String?
    @State private var generatedContent: GeneratedContent?
    @State private var showHistory = false

    private let baseURL = "http://localhost:8000"

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if isGenerating {
                SkeletonLoadingView(generateImages: generateImages)
            } else if let content = generatedContent {
                ContentResultsView(content: content) {
                    generatedContent = nil
                    selectedIdea = nil
                    customTopic = ""
                }
            } else if let error = errorMessage {
                errorView(error)
            } else if isLoadingCompanies {
                loadingView("Loading companies...")
            } else {
                mainContent
            }
        }
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(onSelect: { entry in
                generatedContent = entry.content
                showHistory = false
            })
            .environmentObject(historyManager)
        }
    }

    private var header: some View {
        HStack {
            Text("Social Content Generator")
                .font(.largeTitle.bold())
            Spacer()

            Button(action: { showHistory.toggle() }) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                    if !historyManager.entries.isEmpty {
                        Text("(\(historyManager.entries.count))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("View content history")
            .help("View previously generated content")

            Circle()
                .fill(apiStatus == "healthy" ? .green : .red)
                .frame(width: 12, height: 12)
                .accessibilityLabel("API status: \(apiStatus)")
            Text(apiStatus)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.Spacing.lg)
        .background(.bar)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                // Step 1: Company Selection
                companySection

                if selectedCompany != nil {
                    // Step 2: Get Ideas or Custom Topic
                    ideasSection

                    if selectedIdea != nil || !customTopic.isEmpty {
                        // Step 3: Tone & Generate
                        generateSection
                    }
                }
            }
            .padding(Theme.Spacing.xl)
        }
    }

    // MARK: - Company Section

    private var companySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(
                step: 1,
                title: "Select Company",
                icon: "building.2",
                color: Theme.StepColors.step1
            )

            HStack(spacing: Theme.Spacing.md) {
                ForEach(companies) { company in
                    CompanyCard(
                        company: company,
                        isSelected: selectedCompany?.id == company.id
                    ) {
                        withAnimation(Theme.Animation.standard) {
                            selectedCompany = company
                            ideas = []
                            selectedIdea = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Ideas Section

    private var ideasSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                SectionHeader(
                    step: 2,
                    title: "Choose a Topic",
                    icon: "lightbulb",
                    color: Theme.StepColors.step2
                )
                Spacer()
                if !ideas.isEmpty {
                    Button("Refresh Ideas") {
                        Task { await loadIdeas() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Generate new content ideas")
                }
            }

            if isLoadingIdeas {
                HStack(spacing: Theme.Spacing.sm) {
                    ProgressView()
                    Text("AI is generating ideas...")
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.Spacing.lg)
            } else if ideas.isEmpty {
                Button(action: { Task { await loadIdeas() } }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Content Ideas with AI")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Theme.Spacing.lg)
                }
                .buttonStyle(.bordered)
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(ideas) { idea in
                        IdeaCard(
                            idea: idea,
                            isSelected: selectedIdea?.id == idea.id
                        ) {
                            withAnimation(Theme.Animation.standard) {
                                selectedIdea = idea
                                customTopic = ""
                            }
                        }
                    }
                }
            }

            // Custom topic option
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Or enter your own topic:")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                TextField("Custom topic...", text: $customTopic)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: customTopic) { _, newValue in
                        if !newValue.isEmpty {
                            selectedIdea = nil
                        }
                    }
            }
        }
    }

    // MARK: - Generate Section

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            SectionHeader(
                step: 3,
                title: "Generate Content",
                icon: "wand.and.stars",
                color: Theme.StepColors.step3
            )

            HStack(alignment: .top, spacing: Theme.Spacing.xxl) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Tone")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Picker("Tone", selection: $tone) {
                        ForEach(Tone.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 250)
                    .help("Select the tone for your generated content")
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Variations")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 0) {
                        ForEach([1, 2, 3], id: \.self) { num in
                            Button(action: { variations = num }) {
                                Text("\(num)")
                                    .font(.subheadline.weight(.medium))
                                    .frame(width: 36, height: 24)
                                    .background(variations == num ? Color.accentColor : Color.secondary.opacity(0.15))
                                    .foregroundStyle(variations == num ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(num) variation\(num > 1 ? "s" : "")")
                        }
                    }
                    .cornerRadius(Theme.Radius.sm)
                    .help("Number of content variations to generate")
                }

                Spacer()
            }

            // Image generation options
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Toggle(isOn: $generateImages) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "photo.fill")
                        Text("Generate AI Images")
                    }
                }
                .toggleStyle(.checkbox)

                if generateImages {
                    HStack(spacing: Theme.Spacing.md) {
                        Text("Style:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Picker("Image Style", selection: $imageStyle) {
                            ForEach(ImageStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        Text(imageStyle.description)
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    Text("Image generation adds ~10-20 seconds per platform")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, Theme.Spacing.xs)

            HStack {
                // Preview what will be generated
                if let idea = selectedIdea {
                    Text("Topic: \(idea.title)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if !customTopic.isEmpty {
                    Text("Topic: \(customTopic)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isGenerating {
                    HStack(spacing: Theme.Spacing.sm) {
                        ProgressView()
                        Text(generateImages ? "Generating content & images..." : "Generating...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button(action: generateContent) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(generateImages ? "Generate Posts + Images" : "Generate Posts")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8), Color.purple.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(Theme.Radius.md)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Generate social media posts")
                }
            }
        }
    }

    // MARK: - Helper Views

    private func loadingView(_ message: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Start API: cd services/api && uv run fastapi dev")
                .font(.footnote)
                .foregroundStyle(.tertiary)
            Button("Try Again") {
                errorMessage = nil
                Task { await loadInitialData() }
            }
            .buttonStyle(.bordered)
            .padding(.top, Theme.Spacing.sm)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - API Calls

    private func loadInitialData() async {
        isLoadingCompanies = true
        errorMessage = nil

        // Check health
        do {
            let url = URL(string: "\(baseURL)/health")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let health = try JSONDecoder().decode(HealthResponse.self, from: data)
            apiStatus = health.status
        } catch {
            apiStatus = "offline"
            errorMessage = "API not running"
            isLoadingCompanies = false
            return
        }

        // Load companies
        do {
            let url = URL(string: "\(baseURL)/companies")!
            let (data, _) = try await URLSession.shared.data(from: url)
            companies = try JSONDecoder().decode([Company].self, from: data)
        } catch {
            errorMessage = "Failed to load companies"
        }

        isLoadingCompanies = false
    }

    private func loadIdeas() async {
        guard let company = selectedCompany else { return }

        isLoadingIdeas = true

        do {
            let url = URL(string: "\(baseURL)/ideas/\(company.id)")!
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let ideasResponse = try JSONDecoder().decode(IdeasResponse.self, from: data)
            await MainActor.run {
                ideas = ideasResponse.ideas
                isLoadingIdeas = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to generate ideas: \(error.localizedDescription)"
                isLoadingIdeas = false
            }
        }
    }

    private func generateContent() {
        guard let company = selectedCompany else { return }
        let topic = selectedIdea?.title ?? customTopic
        guard !topic.isEmpty else { return }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let url = URL(string: "\(baseURL)/generate")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let requestBody = GenerateRequest(
                    companyId: company.id,
                    topic: topic,
                    tone: tone,
                    generateImages: generateImages,
                    imageStyle: imageStyle,
                    variations: variations
                )
                request.httpBody = try JSONEncoder().encode(requestBody)

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }

                if httpResponse.statusCode == 200 {
                    let content = try JSONDecoder().decode(GeneratedContent.self, from: data)
                    await MainActor.run {
                        generatedContent = content
                        isGenerating = false
                        // Save to history
                        historyManager.save(content, company: company.name, topic: topic, tone: tone.rawValue)
                    }
                } else {
                    let apiError = try? JSONDecoder().decode(APIError.self, from: data)
                    await MainActor.run {
                        errorMessage = apiError?.detail ?? "Server error: \(httpResponse.statusCode)"
                        isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate content: \(error.localizedDescription)"
                    isGenerating = false
                }
            }
        }
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let step: Int
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("Step \(step)")
                .font(.caption.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.title3.bold())
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.Radius.md)
    }
}

// MARK: - Company Card

struct CompanyCard: View {
    let company: Company
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(company.name)
                    .font(.headline)
                Text(company.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.lg)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(Theme.Radius.lg)
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 4)
                        .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(isSelected ? Color.accentColor : (isHovered ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.15)), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isHovered ? Theme.Shadow.hover.color : Theme.Shadow.card.color,
                radius: isHovered ? Theme.Shadow.hover.radius : Theme.Shadow.card.radius,
                y: isHovered ? Theme.Shadow.hover.y : Theme.Shadow.card.y
            )
            .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.quick, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("Select \(company.name)")
        .accessibilityHint(company.description)
    }
}

// MARK: - Idea Card

struct IdeaCard: View {
    let idea: ContentIdea
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(idea.title)
                        .font(.subheadline.bold())
                    Text(idea.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(Theme.Spacing.lg)
            .background(isSelected ? Color.green.opacity(0.15) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(Theme.Radius.lg)
            .overlay(alignment: .leading) {
                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: 4)
                        .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(isSelected ? Color.green : (isHovered ? Color.secondary.opacity(0.3) : Color.secondary.opacity(0.15)), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(
                color: isHovered ? Theme.Shadow.hover.color : Theme.Shadow.card.color,
                radius: isHovered ? Theme.Shadow.hover.radius : Theme.Shadow.card.radius,
                y: isHovered ? Theme.Shadow.hover.y : Theme.Shadow.card.y
            )
            .scaleEffect(isHovered && !isSelected ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(Theme.Animation.quick, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("Select topic: \(idea.title)")
        .accessibilityHint(idea.description)
    }
}

// MARK: - Skeleton Loading View

struct SkeletonLoadingView: View {
    let generateImages: Bool
    @State private var isAnimating = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header skeleton
                HStack {
                    Text("Generating Content...")
                        .font(.title2.bold())
                    Spacer()
                    ProgressView()
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Info text
                Text(generateImages ? "Creating posts and generating images..." : "Creating platform-specific posts...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Theme.Spacing.lg)

                // Skeleton cards grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: Theme.Spacing.lg),
                    GridItem(.flexible(), spacing: Theme.Spacing.lg)
                ], spacing: Theme.Spacing.lg) {
                    SkeletonCard(platform: "Instagram", icon: "camera.fill", color: Theme.Platform.instagram)
                    SkeletonCard(platform: "LinkedIn", icon: "briefcase.fill", color: Theme.Platform.linkedin)
                    SkeletonCard(platform: "Twitter/X", icon: "bubble.left.fill", color: Theme.Platform.twitter)
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
    }
}

struct SkeletonCard: View {
    let platform: String
    let icon: String
    let color: Color
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(platform)
                    .font(.headline)
                Spacer()
            }

            // Skeleton lines
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                SkeletonLine(width: 1.0)
                SkeletonLine(width: 0.9)
                SkeletonLine(width: 0.75)
                SkeletonLine(width: 0.6)
            }

            Divider()

            // Button skeleton
            SkeletonLine(width: 0.25)
                .frame(height: 28)
        }
        .padding(Theme.Spacing.lg)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(Theme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Theme.Shadow.subtle.color, radius: Theme.Shadow.subtle.radius, y: Theme.Shadow.subtle.y)
    }
}

struct SkeletonLine: View {
    let width: CGFloat
    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.sm)
            .fill(
                LinearGradient(
                    colors: [
                        Color.secondary.opacity(0.1),
                        Color.secondary.opacity(0.2),
                        Color.secondary.opacity(0.1)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: 14)
            .scaleEffect(x: width, anchor: .leading)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    ContentView()
}
