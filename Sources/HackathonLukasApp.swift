import SwiftUI

@main
struct HackathonLukasApp: App {
    @StateObject private var historyManager = HistoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(historyManager)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 700)
    }
}
