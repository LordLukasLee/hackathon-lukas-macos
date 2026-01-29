import Foundation

class HistoryManager: ObservableObject {
    @Published var entries: [HistoryEntry] = []

    private let fileURL: URL

    init() {
        // Get app support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("HackathonLukasClient", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        fileURL = appFolder.appendingPathComponent("history.json")
        load()
    }

    func save(_ content: GeneratedContent, company: String, topic: String, tone: String) {
        let entry = HistoryEntry(company: company, topic: topic, tone: tone, content: content)
        entries.insert(entry, at: 0) // Add to beginning (most recent first)

        // Keep only last 50 entries
        if entries.count > 50 {
            entries = Array(entries.prefix(50))
        }

        persist()
    }

    func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        persist()
    }

    func clearAll() {
        entries.removeAll()
        persist()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([HistoryEntry].self, from: data)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save history: \(error)")
        }
    }
}
