import SwiftUI
import UniformTypeIdentifiers

struct ContentResultsView: View {
    let content: GeneratedContent
    let onGenerateNew: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Generated Content")
                            .font(.title2.bold())
                        Spacer()
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

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    PlatformCard(
                        platform: "Instagram",
                        icon: "camera.fill",
                        color: .pink,
                        content: content.instagram
                    )

                    PlatformCard(
                        platform: "LinkedIn",
                        icon: "briefcase.fill",
                        color: .blue,
                        content: content.linkedin
                    )

                    PlatformCard(
                        platform: "Twitter/X",
                        icon: "bubble.left.fill",
                        color: .cyan,
                        content: content.twitter,
                        showCharWarning: true
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
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
            instagram: PlatformContent(
                content: "Just launched something amazing! Check it out.",
                hashtags: ["launch", "tech"],
                charCount: 45,
                imageSuggestion: "Modern retail store with self-checkout kiosks, bright lighting",
                imageUrl: nil,
                imageStyle: "photo"
            ),
            linkedin: PlatformContent(
                content: "Excited to announce our latest innovation.",
                hashtags: ["innovation", "business"],
                charCount: 50,
                imageSuggestion: "Professional infographic showing checkout time reduction",
                imageUrl: nil,
                imageStyle: "photo"
            ),
            twitter: PlatformContent(
                content: "Big news! We just launched.",
                hashtags: ["launch"],
                charCount: 28,
                imageSuggestion: "Eye-catching stat card with key metric",
                imageUrl: nil,
                imageStyle: "photo"
            )
        ),
        onGenerateNew: {}
    )
    .frame(width: 800, height: 600)
}
