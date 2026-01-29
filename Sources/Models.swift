import Foundation

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

    enum CodingKeys: String, CodingKey {
        case companyId = "company_id"
        case topic
        case tone
    }

    init(companyId: String, topic: String, tone: Tone = .professional) {
        self.companyId = companyId
        self.topic = topic
        self.tone = tone.rawValue
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

struct PlatformContent: Codable {
    let content: String
    let hashtags: [String]
    let charCount: Int
    let imageSuggestion: String

    enum CodingKeys: String, CodingKey {
        case content
        case hashtags
        case charCount = "char_count"
        case imageSuggestion = "image_suggestion"
    }
}

struct GeneratedContent: Codable {
    let company: String
    let topic: String
    let instagram: PlatformContent
    let linkedin: PlatformContent
    let twitter: PlatformContent
    let tiktok: PlatformContent
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
