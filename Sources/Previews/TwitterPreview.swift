import SwiftUI

struct TwitterPreview: View {
    let content: PlatformContent
    let companyName: String

    @State private var copied = false

    private var handle: String {
        "@" + companyName.lowercased().replacingOccurrences(of: " ", with: "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(companyName.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    // Header
                    HStack(spacing: 4) {
                        Text(companyName)
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                        Text(handle)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text("2h")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    // Tweet content
                    Text(content.content)
                        .font(.system(size: 15))
                        .lineLimit(nil)
                        .padding(.top, 2)

                    // Image (if available)
                    if let imageUrl = content.imageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.2))
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .overlay(ProgressView())
                                    .padding(.top, 12)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .padding(.top, 12)
                            case .failure:
                                imagePlaceholder
                                    .padding(.top, 12)
                            @unknown default:
                                imagePlaceholder
                                    .padding(.top, 12)
                            }
                        }
                    } else if !content.imageSuggestion.isEmpty {
                        imagePlaceholder
                            .padding(.top, 12)
                    }

                    // Engagement buttons
                    HStack(spacing: 0) {
                        twitterButton(icon: "bubble.left", count: "12")
                        twitterButton(icon: "arrow.2.squarepath", count: "34")
                        twitterButton(icon: "heart", count: "156")
                        twitterButton(icon: "chart.bar", count: "2.4K")
                        HStack(spacing: 16) {
                            Image(systemName: "bookmark")
                            Image(systemName: "square.and.arrow.up")
                        }
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                    }
                    .padding(.top, 12)
                }
            }
            .padding(16)

            // Character count warning
            if content.charCount > 280 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text("Over character limit: \(content.charCount)/280")
                        .font(.caption)
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Copy button
            Divider()
            Button(action: copyToClipboard) {
                HStack {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    Text(copied ? "Copied!" : "Copy Tweet")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .foregroundStyle(copied ? .green : .accentColor)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 500)
    }

    private func twitterButton(icon: String, count: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(count)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(LinearGradient(
                colors: [.cyan.opacity(0.2), .blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .aspectRatio(16/9, contentMode: .fit)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                    Text("Image Preview")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            )
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content.content, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

#Preview {
    TwitterPreview(
        content: PlatformContent(
            content: "What if checkout took 10 seconds instead of 10 minutes? Now it does. #RetailTech",
            hashtags: ["RetailTech"],
            charCount: 82,
            imageSuggestion: "Eye-catching visual",
            imageUrl: nil,
            imageStyle: "photo"
        ),
        companyName: "Phygrid"
    )
    .padding()
    .frame(width: 550)
}
