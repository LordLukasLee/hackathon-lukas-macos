import SwiftUI
import UniformTypeIdentifiers

struct ContentResultsView: View {
    let content: GeneratedContent
    let onGenerateNew: () -> Void

    @State private var selectedVariation = 0
    @State private var appeared = false

    private var variationCount: Int {
        content.instagram.count
    }

    private var variationLabels: [String] {
        ["A", "B", "C"].prefix(variationCount).map { String($0) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Text("Generated Content")
                            .font(.title2.bold())
                        Spacer()

                        Button("Generate New") {
                            onGenerateNew()
                        }
                        .buttonStyle(.bordered)
                        .help("Create new content")
                    }
                    HStack {
                        Text(content.company)
                            .font(.subheadline)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(Color.accentColor.opacity(0.15))
                            .cornerRadius(Theme.Radius.sm)
                        Text(content.topic)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Variation tabs (only show if multiple variations)
                if variationCount > 1 {
                    HStack(spacing: 0) {
                        ForEach(0..<variationCount, id: \.self) { index in
                            Button(action: {
                                withAnimation(Theme.Animation.standard) {
                                    selectedVariation = index
                                }
                            }) {
                                Text(variationLabels[index])
                                    .font(.headline)
                                    .frame(width: 50, height: 36)
                                    .background(selectedVariation == index ? Color.accentColor : Color.clear)
                                    .foregroundStyle(selectedVariation == index ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Variation \(variationLabels[index])")
                        }
                    }
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(Theme.Radius.md)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .animation(Theme.Animation.standard, value: selectedVariation)
                }

                // Content grid
                cardView
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .padding(.vertical, Theme.Spacing.lg)
            .animation(Theme.Animation.standard, value: selectedVariation)
        }
        .onAppear {
            withAnimation(Theme.Animation.smooth) {
                appeared = true
            }
        }
    }

    private var cardView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: Theme.Spacing.lg),
            GridItem(.flexible(), spacing: Theme.Spacing.lg)
        ], spacing: Theme.Spacing.lg) {
            PlatformCard(
                platform: "Instagram",
                icon: "camera.fill",
                color: Theme.Platform.instagram,
                content: content.instagram[safe: selectedVariation] ?? content.instagram[0]
            )

            PlatformCard(
                platform: "LinkedIn",
                icon: "briefcase.fill",
                color: Theme.Platform.linkedin,
                content: content.linkedin[safe: selectedVariation] ?? content.linkedin[0]
            )

            PlatformCard(
                platform: "Twitter/X",
                icon: "bubble.left.fill",
                color: Theme.Platform.twitter,
                content: content.twitter[safe: selectedVariation] ?? content.twitter[0],
                showCharWarning: true
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
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
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
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
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "photo.fill")
                        Text("Generated Image")
                        Spacer()
                        Button(action: { saveImage(from: url) }) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: imageSaved ? "checkmark" : "square.and.arrow.down")
                                Text(imageSaved ? "Saved!" : "Save")
                            }
                            .font(.footnote)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(imageSaved ? .green : nil)
                        .accessibilityLabel(imageSaved ? "Image saved" : "Save image")
                    }
                    .font(.footnote)
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
                                .cornerRadius(Theme.Radius.md)
                        case .failure:
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                Text("Failed to load image")
                            }
                            .font(.footnote)
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
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text(content.imageSuggestion)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Button(action: copyImageSuggestion) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Image(systemName: promptCopied ? "checkmark" : "photo")
                                Text(promptCopied ? "Copied!" : "Copy for AI image generator")
                            }
                            .font(.footnote)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(promptCopied ? .green : .orange)
                    }
                    .padding(.top, Theme.Spacing.xs)
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "photo.fill")
                        Text("Image Prompt")
                    }
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
            }

            Divider()

            HStack {
                Button(action: copyToClipboard) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy")
                    }
                }
                .buttonStyle(.bordered)
                .tint(copied ? .green : nil)
                .accessibilityLabel(copied ? "Content copied" : "Copy content to clipboard")

                Spacer()
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(Theme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(color.opacity(isHovered ? 0.5 : 0.3), lineWidth: isHovered ? 2 : 1)
        )
        .shadow(
            color: isHovered ? Theme.Shadow.hover.color : Theme.Shadow.subtle.color,
            radius: isHovered ? Theme.Shadow.hover.radius : Theme.Shadow.subtle.radius,
            y: isHovered ? Theme.Shadow.hover.y : Theme.Shadow.subtle.y
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(Theme.Animation.standard, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel("\(platform) content card")
    }

    private var charCountBadge: some View {
        let isOverLimit = showCharWarning && content.charCount > 280
        return Text("\(content.charCount) chars")
            .font(.footnote)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isOverLimit ? Color.red.opacity(0.2) : Color.secondary.opacity(0.1))
            .foregroundStyle(isOverLimit ? .red : .secondary)
            .cornerRadius(Theme.Radius.sm)
            .accessibilityLabel("\(content.charCount) characters\(isOverLimit ? ", over Twitter limit" : "")")
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
