import SwiftUI

struct InstagramPreview: View {
    let content: PlatformContent
    let companyName: String

    @State private var copied = false

    private var handle: String {
        companyName.lowercased().replacingOccurrences(of: " ", with: "_")
    }

    private var postText: String {
        // Extract content without hashtags for cleaner display
        let lines = content.content.components(separatedBy: "\n\n")
        if lines.count > 1 {
            return lines.dropLast().joined(separator: "\n\n")
        }
        return content.content
    }

    private var hashtagText: String {
        content.hashtags.map { "#\($0)" }.joined(separator: " ")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [.purple, .pink, .orange, .yellow],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(companyName.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(handle)
                        .font(.system(size: 13, weight: .semibold))
                    Text("Sponsored")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Image placeholder
            if let imageUrl = content.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                    case .failure:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }

            // Action buttons
            HStack(spacing: 16) {
                HStack(spacing: 16) {
                    Image(systemName: "heart")
                    Image(systemName: "bubble.right")
                    Image(systemName: "paperplane")
                }
                Spacer()
                Image(systemName: "bookmark")
            }
            .font(.system(size: 22))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            // Likes
            HStack {
                Text("1,234 likes")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 4)

            // Caption
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 4) {
                    Text(handle)
                        .font(.system(size: 13, weight: .semibold))
                    Text(postText)
                        .font(.system(size: 13))
                        .lineLimit(3)
                }

                if !content.hashtags.isEmpty {
                    Text(hashtagText)
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                }

                Text("View all 42 comments")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)

                Text("2 HOURS AGO")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)

            // Copy button
            Divider()
            Button(action: copyToClipboard) {
                HStack {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    Text(copied ? "Copied!" : "Copy Post")
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
                .stroke(Color.pink.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 400)
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.pink.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
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
    InstagramPreview(
        content: PlatformContent(
            content: "Just launched something amazing! Our new self-checkout system reduces wait times by 80%.\n\nWhat's the longest you've waited in a checkout line?\n\n#RetailTech #Innovation #SelfCheckout",
            hashtags: ["RetailTech", "Innovation", "SelfCheckout"],
            charCount: 150,
            imageSuggestion: "Modern retail store",
            imageUrl: nil,
            imageStyle: "photo"
        ),
        companyName: "Phygrid"
    )
    .padding()
    .frame(width: 450)
}
