import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var historyManager: HistoryManager
    @Environment(\.dismiss) private var dismiss
    let onSelect: (HistoryEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Content History")
                    .font(.title2.bold())
                Spacer()
                if !historyManager.entries.isEmpty {
                    Button("Clear All", role: .destructive) {
                        historyManager.clearAll()
                    }
                    .buttonStyle(.bordered)
                    .help("Remove all history entries")
                }
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Close history")
            }
            .padding(Theme.Spacing.lg)
            .background(.bar)

            Divider()

            if historyManager.entries.isEmpty {
                VStack(spacing: Theme.Spacing.md) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .font(.headline)
                    Text("Generated content will appear here")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(historyManager.entries) { entry in
                        HistoryRow(entry: entry, onSelect: {
                            onSelect(entry)
                        }, onDelete: {
                            historyManager.delete(entry.id)
                        })
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

struct HistoryRow: View {
    let entry: HistoryEntry
    let onSelect: () -> Void
    let onDelete: () -> Void

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: entry.createdAt, relativeTo: Date())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text(entry.company)
                        .font(.footnote)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(Theme.Radius.sm)
                    Text(entry.tone.capitalized)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedDate)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                Text(entry.topic)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()

            Button("View") {
                onSelect()
            }
            .buttonStyle(.bordered)
            .help("View this generated content")

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .accessibilityLabel("Delete history entry")
            .help("Delete this entry")
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    HistoryView(onSelect: { _ in })
        .environmentObject(HistoryManager())
}
