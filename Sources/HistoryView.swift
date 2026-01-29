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
                }
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.bar)

            Divider()

            if historyManager.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No history yet")
                        .font(.headline)
                    Text("Generated content will appear here")
                        .font(.caption)
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
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.company)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                    Text(entry.tone.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedDate)
                        .font(.caption)
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

            Button(action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView(onSelect: { _ in })
        .environmentObject(HistoryManager())
}
