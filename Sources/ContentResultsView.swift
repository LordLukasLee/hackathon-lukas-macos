import SwiftUI
import UniformTypeIdentifiers

enum ViewMode: String, CaseIterable {
    case card = "Card"
    case preview = "Preview"
}

struct ContentResultsView: View {
    let content: GeneratedContent
    let onGenerateNew: () -> Void

    @State private var selectedVariation = 0
    @State private var viewMode: ViewMode = .card

    private var variationCount: Int {
        content.instagram.count
    }

    private var variationLabels: [String] {
        ["A", "B", "C"].prefix(variationCount).map { String($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generated Content")
                            .font(.title2.bold())
                        Spacer()

                        // View mode toggle
                        Picker("View", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)

                        Button("Generate New") {
                            onGenerateNew()
                        }
                        .buttonStyle(.bordered)
                    }
                    HStack {
                        Text(content.company)
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                        Text(content.topic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                // Variation tabs (only show if multiple variations)
                if variationCount > 1 {
                    HStack(spacing: 0) {
                        ForEach(0..<variationCount, id: \.self) { index in
                            Button(action: { selectedVariation = index }) {
                                Text(variationLabels[index])
                                    .font(.headline)
                                    .frame(width: 50, height: 36)
                                    .background(selectedVariation == index ? Color.accentColor : Color.clear)
                                    .foregroundStyle(selectedVariation == index ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }

                // Content grid
                if viewMode == .card {
                    cardView
                } else {
                    previewView
                }
            }
            .padding(.vertical)
        }
    }

    private var cardView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            PlatformCard(
                platform: "Instagram",
                icon: "camera.fill",
                color: .pink,
                content: content.instagram[safe: selectedVariation] ?? content.instagram[0]
            )

            PlatformCard(
                platform: "LinkedIn",
                icon: "briefcase.fill",
                color: .blue,
                content: content.linkedin[safe: selectedVariation] ?? content.linkedin[0]
            )

            PlatformCard(
                platform: "Twitter/X",
                icon: "bubble.left.fill",
                color: .cyan,
                content: content.twitter[safe: selectedVariation] ?? content.twitter[0],
                showCharWarning: true
            )
        }
        .padding(.horizontal)
    }

    private var previewView: some View {
        VStack(spacing: 24) {
            // Instagram Preview
            InstagramPreview(
                content: content.instagram[safe: selectedVariation] ?? content.instagram[0],
                companyName: content.company
            )

            // LinkedIn Preview
            LinkedInPreview(
                content: content.linkedin[safe: selectedVariation] ?? content.linkedin[0],
                companyName: content.company
            )

            // Twitter Preview
            TwitterPreview(
                content: content.twitter[safe: selectedVariation] ?? content.twitter[0],
                companyName: content.company
            )
        }
        .padding(.horizontal)
    }
}

// Safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct PlatformCard: View {
    let platform: String
    let icon: String
    let color: Color
    let content: PlatformContent
    var showCharWarning: Bool = false

    @State private var copied = false
    @State private var imageSaved = false
    @State private var promptCopied = false
    @State private var showImageSuggestion = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(platform)
                    .font(.headline)
                Spacer()
                charCountBadge
            }

            Text(content.content)
                .font(.body)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(nil)

            // Generated Image Section
            if let imageUrl = content.imageUrl, let url = URL(string: imageUrl) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                        Text("Generated Image")
                        Spacer()
                        Button(action: { saveImage(from: url) }) {
                            HStack(spacing: 4) {
                                Image(systemName: imageSaved ? "checkmark" : "square.and.arrow.down")
                                Text(imageSaved ? "Saved!" : "Save")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(imageSaved ? .green : nil)
                    }
                    .font(.caption)
                    .foregroundStyle(.green)

                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            HStack {
                                Spacer()
                                ProgressView()
                                    .frame(height: 150)
                                Spacer()
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                        case .failure:
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("Failed to load image")
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(height: 100)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }

            // Always show image suggestion when available (for copying to external image generators)
            if !content.imageSuggestion.isEmpty {
                DisclosureGroup(isExpanded: $showImageSuggestion) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(content.imageSuggestion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Button(action: copyImageSuggestion) {
                            HStack(spacing: 4) {
                                Image(systemName: promptCopied ? "checkmark" : "photo")
                                Text(promptCopied ? "Copied!" : "Copy for AI image generator")
                            }
                            .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(promptCopied ? .green : .orange)
                    }
                    .padding(.top, 4)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.fill")
                        Text("Image Prompt")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }

            Divider()

            HStack {
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy")
                    }
                }
                .buttonStyle(.bordered)
                .tint(copied ? .green : nil)

                Spacer()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }

    private var charCountBadge: some View {
        let isOverLimit = showCharWarning && content.charCount > 280
        return Text("\(content.charCount) chars")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOverLimit ? Color.red.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(isOverLimit ? .red : .secondary)
            .cornerRadius(6)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content.content, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }

    private func copyImageSuggestion() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content.imageSuggestion, forType: .string)
        promptCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            promptCopied = false
        }
    }

    private func saveImage(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = NSImage(data: data) else { return }

                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [.png, .jpeg]
                savePanel.nameFieldStringValue = "\(platform.lowercased())_image.png"

                if savePanel.runModal() == .OK, let saveUrl = savePanel.url {
                    if let tiffData = image.tiffRepresentation,
                       let bitmapRep = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapRep.representation(using: .png, properties: [:])
                    {
                        try pngData.write(to: saveUrl)
                        await MainActor.run {
                            imageSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                imageSaved = false
                            }
                        }
                    }
                }
            } catch {
                print("Error saving image: \(error)")
            }
        }
    }
}

#Preview {
    ContentResultsView(
        content: GeneratedContent(
            company: "Phygrid",
            topic: "New self-checkout feature",
            instagram: [
                PlatformContent(
                    content: "Just launched something amazing! Check it out.\n\n#launch #tech",
                    hashtags: ["launch", "tech"],
                    charCount: 55,
                    imageSuggestion: "Modern retail store with self-checkout kiosks, bright lighting",
                    imageUrl: nil,
                    imageStyle: "photo"
                ),
                PlatformContent(
                    content: "What if checkout took 10 seconds? Now it does.\n\n#retail #innovation",
                    hashtags: ["retail", "innovation"],
                    charCount: 60,
                    imageSuggestion: "Futuristic checkout experience",
                    imageUrl: nil,
                    imageStyle: "photo"
                )
            ],
            linkedin: [
                PlatformContent(
                    content: "Excited to announce our latest innovation in retail technology.",
                    hashtags: ["innovation", "business"],
                    charCount: 70,
                    imageSuggestion: "Professional infographic showing checkout time reduction",
                    imageUrl: nil,
                    imageStyle: "photo"
                ),
                PlatformContent(
                    content: "The future of retail isn't coming. It's already here.",
                    hashtags: ["retail", "future"],
                    charCount: 55,
                    imageSuggestion: "Team celebrating product launch",
                    imageUrl: nil,
                    imageStyle: "photo"
                )
            ],
            twitter: [
                PlatformContent(
                    content: "Big news! We just launched.",
                    hashtags: ["launch"],
                    charCount: 28,
                    imageSuggestion: "Eye-catching stat card with key metric",
                    imageUrl: nil,
                    imageStyle: "photo"
                ),
                PlatformContent(
                    content: "What if you never had to wait in line again?",
                    hashtags: [],
                    charCount: 45,
                    imageSuggestion: "Before/after comparison of checkout lines",
                    imageUrl: nil,
                    imageStyle: "photo"
                )
            ]
        ),
        onGenerateNew: {}
    )
    .frame(width: 800, height: 600)
}
