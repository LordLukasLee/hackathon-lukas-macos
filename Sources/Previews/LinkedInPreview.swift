import SwiftUI

struct LinkedInPreview: View {
    let content: PlatformContent
    let companyName: String

    @State private var copied = false

    private var postText: String {
        // Extract content without hashtags
        let lines = content.content.components(separatedBy: "\n\n")
        if lines.count > 1, let lastLine = lines.last, lastLine.hasPrefix("#") {
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
            HStack(alignment: .top, spacing: 12) {
                // Company avatar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(companyName.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(companyName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Company • 12,345 followers")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 4) {
                        Text("2h")
                        Text("•")
                        Image(systemName: "globe")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            // Post content
            VStack(alignment: .leading, spacing: 8) {
                Text(postText)
                    .font(.system(size: 14))
                    .lineLimit(nil)

                if !content.hashtags.isEmpty {
                    Text(hashtagText)
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Image
            if let imageUrl = content.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 250)
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

            // Engagement stats
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.blue)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.white)
                        )
                    Text("42")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("7 comments • 3 reposts")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()
                .padding(.horizontal, 16)

            // Action buttons
            HStack(spacing: 0) {
                linkedInButton(icon: "hand.thumbsup", label: "Like")
                linkedInButton(icon: "bubble.left", label: "Comment")
                linkedInButton(icon: "arrow.2.squarepath", label: "Repost")
                linkedInButton(icon: "paperplane", label: "Send")
            }
            .padding(.vertical, 4)

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
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .frame(maxWidth: 500)
    }

    private func linkedInButton(icon: String, label: String) -> some View {
        Button(action: {}) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(LinearGradient(
                colors: [.blue.opacity(0.2), .cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .aspectRatio(16/9, contentMode: .fit)
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
    LinkedInPreview(
        content: PlatformContent(
            content: "The checkout experience is broken.\n\nCustomers wait an average of 8 minutes in line. That's 8 minutes of frustration, 8 minutes of lost productivity, 8 minutes that could make or break a sale.\n\nWe built something to fix it.\n\n#RetailTech #CustomerExperience",
            hashtags: ["RetailTech", "CustomerExperience"],
            charCount: 280,
            imageSuggestion: "Professional infographic",
            imageUrl: nil,
            imageStyle: "photo"
        ),
        companyName: "Phygrid"
    )
    .padding()
    .frame(width: 550)
}
