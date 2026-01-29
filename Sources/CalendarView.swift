import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var scheduleManager: ScheduleManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        HStack(spacing: 0) {
            // Left: Calendar
            calendarPanel
                .frame(width: 320)

            Divider()

            // Right: Posts for selected day
            postsPanel
                .frame(minWidth: 350)
        }
        .frame(minWidth: 700, minHeight: 500)
    }

    // MARK: - Calendar Panel

    private var calendarPanel: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Header with month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearString)
                    .font(.headline)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.md)

            // Days of week header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Theme.Spacing.sm) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasPost: scheduleManager.datesWithPosts(in: displayedMonth).contains(calendar.startOfDay(for: date))
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Text("")
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                }
            }

            Spacer()

            // Close button
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.escape)
        }
        .padding(Theme.Spacing.lg)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Posts Panel

    private var postsPanel: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.orange)
                Text(dateString(for: selectedDate))
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)

            let postsForDay = scheduleManager.postsForDate(selectedDate)

            if postsForDay.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No posts scheduled")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.md) {
                        ForEach(postsForDay) { post in
                            ScheduledPostCard(post: post, onMarkPosted: {
                                scheduleManager.markAsPosted(post.id)
                            }, onDelete: {
                                scheduleManager.delete(post.id)
                            })
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                }
            }
        }
    }

    // MARK: - Helper Properties

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }

        var days: [Date?] = []

        // Add empty cells for days before the first of the month
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // Add all days in the month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return days
    }

    // MARK: - Actions

    private func previousMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    private func nextMonth() {
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasPost: Bool
    let onTap: () -> Void

    private let calendar = Calendar.current

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.body)
                    .foregroundStyle(isSelected ? .white : (isToday ? .accentColor : .primary))

                if hasPost {
                    Circle()
                        .fill(isSelected ? .white : .orange)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .fill(isSelected ? Color.accentColor : (isToday ? Color.accentColor.opacity(0.1) : Color.clear))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scheduled Post Card

struct ScheduledPostCard: View {
    let post: ScheduledPost
    let onMarkPosted: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: post.scheduledDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: post.platform.icon)
                    .foregroundStyle(post.platform.color)
                Text(post.platform.displayName)
                    .font(.subheadline.bold())
                Spacer()
                Text(timeString)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if post.isPosted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            // Content preview
            Text(post.content.content)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            // Meta info
            HStack {
                Text(post.company)
                    .font(.caption)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(Theme.Radius.sm)

                Text(post.topic)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)

                Spacer()
            }

            // Actions
            if !post.isPosted {
                HStack {
                    Button(action: onMarkPosted) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark")
                            Text("Mark Posted")
                        }
                        .font(.footnote)
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)

                    Button(action: onDelete) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "trash")
                            Text("Delete")
                        }
                        .font(.footnote)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)

                    Spacer()
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(Theme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(post.platform.color.opacity(isHovered ? 0.5 : 0.2), lineWidth: 1)
        )
        .shadow(color: Theme.Shadow.subtle.color, radius: Theme.Shadow.subtle.radius, y: Theme.Shadow.subtle.y)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(Theme.Animation.quick, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(ScheduleManager())
}
