import Foundation
import UserNotifications

@MainActor
class ScheduleManager: ObservableObject {
    @Published var posts: [ScheduledPost] = []

    private let fileURL: URL
    private var notificationCenter: UNUserNotificationCenter?

    init() {
        // Get app support directory
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("HackathonLukasClient", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        fileURL = appFolder.appendingPathComponent("scheduled_posts.json")
        load()
        setupNotifications()
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        // Check if we're running in a proper bundle context (swift run doesn't provide one)
        guard Bundle.main.bundleIdentifier != nil,
              Bundle.main.bundlePath.hasSuffix(".app") else {
            print("Notifications not available - not running as bundled app")
            return
        }

        notificationCenter = UNUserNotificationCenter.current()
        requestNotificationPermission()
    }

    func requestNotificationPermission() {
        notificationCenter?.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
            print("Notification permission granted: \(granted)")
        }
    }

    // MARK: - CRUD Operations

    func schedule(platform: Platform, content: PlatformContent, date: Date, company: String, topic: String) {
        let post = ScheduledPost(
            platform: platform,
            content: content,
            scheduledDate: date,
            company: company,
            topic: topic
        )
        posts.append(post)
        posts.sort { $0.scheduledDate < $1.scheduledDate }
        persist()
        scheduleNotification(for: post)
    }

    func delete(_ id: UUID) {
        if let post = posts.first(where: { $0.id == id }) {
            cancelNotification(for: post)
        }
        posts.removeAll { $0.id == id }
        persist()
    }

    func markAsPosted(_ id: UUID) {
        if let index = posts.firstIndex(where: { $0.id == id }) {
            posts[index].isPosted = true
            cancelNotification(for: posts[index])
            persist()
        }
    }

    func postsForDate(_ date: Date) -> [ScheduledPost] {
        let calendar = Calendar.current
        return posts.filter { post in
            calendar.isDate(post.scheduledDate, inSameDayAs: date)
        }
    }

    func datesWithPosts(in month: Date) -> Set<Date> {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        return Set(posts.compactMap { post in
            guard post.scheduledDate >= monthInterval.start && post.scheduledDate < monthInterval.end else {
                return nil
            }
            return calendar.startOfDay(for: post.scheduledDate)
        })
    }

    // MARK: - Notifications

    private func scheduleNotification(for post: ScheduledPost) {
        guard let notificationCenter = notificationCenter else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to post on \(post.platform.displayName)!"
        content.body = String(post.content.content.prefix(100)) + (post.content.content.count > 100 ? "..." : "")
        content.sound = .default
        content.categoryIdentifier = "SCHEDULED_POST"

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: post.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: post.notificationId, content: content, trigger: trigger)

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelNotification(for post: ScheduledPost) {
        notificationCenter?.removePendingNotificationRequests(withIdentifiers: [post.notificationId])
    }

    // MARK: - Persistence

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            posts = try decoder.decode([ScheduledPost].self, from: data)
        } catch {
            print("Failed to load scheduled posts: \(error)")
        }
    }

    private func persist() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(posts)
            try data.write(to: fileURL)
        } catch {
            print("Failed to save scheduled posts: \(error)")
        }
    }
}
