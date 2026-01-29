import Foundation
import SwiftUI

// MARK: - Platform

enum Platform: String, Codable, CaseIterable, Identifiable {
    case instagram
    case linkedin
    case twitter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .linkedin: return "LinkedIn"
        case .twitter: return "Twitter/X"
        }
    }

    var icon: String {
        switch self {
        case .instagram: return "camera.fill"
        case .linkedin: return "briefcase.fill"
        case .twitter: return "bubble.left.fill"
        }
    }

    var color: Color {
        switch self {
        case .instagram: return .pink
        case .linkedin: return .blue
        case .twitter: return .cyan
        }
    }
}

// MARK: - Scheduled Post

struct ScheduledPost: Codable, Identifiable {
    let id: UUID
    let platform: Platform
    let content: PlatformContent
    let scheduledDate: Date
    let company: String
    let topic: String
    var isPosted: Bool
    let createdAt: Date
    let notificationId: String

    init(
        platform: Platform,
        content: PlatformContent,
        scheduledDate: Date,
        company: String,
        topic: String
    ) {
        self.id = UUID()
        self.platform = platform
        self.content = content
        self.scheduledDate = scheduledDate
        self.company = company
        self.topic = topic
        self.isPosted = false
        self.createdAt = Date()
        self.notificationId = UUID().uuidString
    }
}

// MARK: - Company Models

struct Company: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
}

// MARK: - Content Ideas

struct ContentIdea: Codable, Identifiable, Hashable {
    let title: String
    let description: String

    var id: String { title }
}

struct IdeasResponse: Codable {
    let company: String
    let ideas: [ContentIdea]
}

// MARK: - Content Generation

struct GenerateRequest: Codable {
    let companyId: String
    let topic: String
    let tone: String
    let generateImages: Bool
    let imageStyle: String
    let variations: Int

    enum CodingKeys: String, CodingKey {
        case companyId = "company_id"
        case topic
        case tone
        case generateImages = "generate_images"
        case imageStyle = "image_style"
        case variations
    }

    init(
        companyId: String,
        topic: String,
        tone: Tone = .professional,
        generateImages: Bool = false,
        imageStyle: ImageStyle = .photo,
        variations: Int = 1
    ) {
        self.companyId = companyId
        self.topic = topic
        self.tone = tone.rawValue
        self.generateImages = generateImages
        self.imageStyle = imageStyle.rawValue
        self.variations = variations
    }
}

enum Tone: String, CaseIterable, Identifiable {
    case professional = "professional"
    case casual = "casual"
    case fun = "fun"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .fun: return "Fun"
        }
    }
}

enum ImageStyle: String, CaseIterable, Identifiable {
    case photo = "photo"
    case illustration = "illustration"
    case infographic = "infographic"
    case minimalist = "minimalist"
    case threeD = "3d"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .photo: return "Photo"
        case .illustration: return "Illustration"
        case .infographic: return "Infographic"
        case .minimalist: return "Minimalist"
        case .threeD: return "3D Render"
        }
    }

    var description: String {
        switch self {
        case .photo: return "Professional photography style"
        case .illustration: return "Digital illustration with vibrant colors"
        case .infographic: return "Clean data visualization style"
        case .minimalist: return "Simple, clean design"
        case .threeD: return "3D rendered graphics"
        }
    }
}

struct PlatformContent: Codable {
    let content: String
    let hashtags: [String]
    let charCount: Int
    let imageSuggestion: String
    let imageUrl: String?
    let imageStyle: String

    enum CodingKeys: String, CodingKey {
        case content
        case hashtags
        case charCount = "char_count"
        case imageSuggestion = "image_suggestion"
        case imageUrl = "image_url"
        case imageStyle = "image_style"
    }
}

struct GeneratedContent: Codable {
    let company: String
    let topic: String
    let instagram: [PlatformContent]  // List of variations
    let linkedin: [PlatformContent]
    let twitter: [PlatformContent]
}

// MARK: - History

struct HistoryEntry: Codable, Identifiable {
    let id: UUID
    let company: String
    let topic: String
    let tone: String
    let content: GeneratedContent
    let createdAt: Date

    init(company: String, topic: String, tone: String, content: GeneratedContent) {
        self.id = UUID()
        self.company = company
        self.topic = topic
        self.tone = tone
        self.content = content
        self.createdAt = Date()
    }
}

// MARK: - API

struct HealthResponse: Codable {
    let status: String
}

struct APIError: Codable {
    let detail: String
}
