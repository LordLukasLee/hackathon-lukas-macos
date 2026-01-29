import SwiftUI

struct SchedulePostSheet: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    let platform: Platform
    let content: PlatformContent
    let company: String
    let topic: String

    @State private var selectedDate = Date()
    @State private var selectedTime = Date()

    private var combinedDateTime: Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute

        return calendar.date(from: combined) ?? selectedDate
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundStyle(platform.color)
                Text("Schedule for \(platform.displayName)")
                    .font(.title2.bold())
                Spacer()
            }
            .padding(.bottom, Theme.Spacing.sm)

            // Content preview
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Content Preview")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(content.content)
                    .font(.body)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.md)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(Theme.Radius.md)
            }

            Divider()

            // Date and Time pickers
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text("Date")
                        .font(.headline)
                    Spacer()
                    DatePicker("", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                        .labelsHidden()
                }

                HStack {
                    Text("Time")
                        .font(.headline)
                    Spacer()
                    DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.escape)

                Spacer()

                Button(action: schedulePost) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Schedule")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(width: 400, height: 400)
    }

    private func schedulePost() {
        scheduleManager.schedule(
            platform: platform,
            content: content,
            date: combinedDateTime,
            company: company,
            topic: topic
        )
        dismiss()
    }
}

#Preview {
    SchedulePostSheet(
        platform: .instagram,
        content: PlatformContent(
            content: "Just launched something amazing! Check it out.\n\n#launch #tech",
            hashtags: ["launch", "tech"],
            charCount: 55,
            imageSuggestion: "Modern retail store",
            imageUrl: nil,
            imageStyle: "photo"
        ),
        company: "Test Company",
        topic: "New Feature Launch"
    )
    .environmentObject(ScheduleManager())
}
