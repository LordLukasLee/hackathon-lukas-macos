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

            if let content = generatedContent {
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
                .font(.title.bold())
            Spacer()

            Button(action: { showHistory.toggle() }) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("History")
                    if !historyManager.entries.isEmpty {
                        Text("(\(historyManager.entries.count))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.bordered)

            Circle()
                .fill(apiStatus == "healthy" ? .green : .red)
                .frame(width: 12, height: 12)
            Text(apiStatus)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.bar)
    }

    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Step 1: Company Selection
                companySection

                if selectedCompany != nil {
                    Divider()

                    // Step 2: Get Ideas or Custom Topic
                    ideasSection

                    if selectedIdea != nil || !customTopic.isEmpty {
                        Divider()

                        // Step 3: Tone & Generate
                        generateSection
                    }
                }
            }
            .padding(24)
        }
    }

    // MARK: - Company Section

    private var companySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Step 1: Select Company", systemImage: "building.2")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(companies) { company in
                    CompanyCard(
                        company: company,
                        isSelected: selectedCompany?.id == company.id
                    ) {
                        withAnimation {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Step 2: Choose a Topic", systemImage: "lightbulb")
                    .font(.headline)
                Spacer()
                if !ideas.isEmpty {
                    Button("Refresh Ideas") {
                        Task { await loadIdeas() }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            if isLoadingIdeas {
                HStack {
                    ProgressView()
                    Text("AI is generating ideas...")
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else if ideas.isEmpty {
                Button(action: { Task { await loadIdeas() } }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Content Ideas with AI")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.bordered)
            } else {
                VStack(spacing: 8) {
                    ForEach(ideas) { idea in
                        IdeaCard(
                            idea: idea,
                            isSelected: selectedIdea?.id == idea.id
                        ) {
                            withAnimation {
                                selectedIdea = idea
                                customTopic = ""
                            }
                        }
                    }
                }
            }

            // Custom topic option
            VStack(alignment: .leading, spacing: 8) {
                Text("Or enter your own topic:")
                    .font(.subheadline)
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Step 3: Generate Content", systemImage: "wand.and.stars")
                .font(.headline)

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tone")
                        .font(.subheadline)
                    Picker("Tone", selection: $tone) {
                        ForEach(Tone.allCases) { t in
                            Text(t.displayName).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }

                Spacer()
            }

            // Image generation options
            VStack(alignment: .leading, spacing: 8) {
                Toggle(isOn: $generateImages) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                        Text("Generate AI Images")
                    }
                }
                .toggleStyle(.checkbox)

                if generateImages {
                    HStack(spacing: 12) {
                        Text("Style:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Image Style", selection: $imageStyle) {
                            ForEach(ImageStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                        Text(imageStyle.description)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Text("⚠️ Image generation adds ~10-20 seconds per platform")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)

            HStack {
                // Preview what will be generated
                if let idea = selectedIdea {
                    Text("Topic: \(idea.title)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if !customTopic.isEmpty {
                    Text("Topic: \(customTopic)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isGenerating {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(generateImages ? "Generating content & images..." : "Generating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button(action: generateContent) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text(generateImages ? "Generate Posts + Images" : "Generate Posts")
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(error)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Start API: cd services/api && uv run fastapi dev")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Button("Try Again") {
                errorMessage = nil
                Task { await loadInitialData() }
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
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
                    imageStyle: imageStyle
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

// MARK: - Company Card

struct CompanyCard: View {
    let company: Company
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 4) {
                Text(company.name)
                    .font(.headline)
                Text(company.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Idea Card

struct IdeaCard: View {
    let idea: ContentIdea
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(idea.title)
                        .font(.subheadline.bold())
                    Text(idea.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.green : Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
