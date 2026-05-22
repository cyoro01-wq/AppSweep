import SwiftUI

@main
struct AIConversationRecorderApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
        }
    }
}

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var transcriptionEngine: String = TranscriptionServiceFactory.isWhisperKitAvailable ? "whisperkit" : "apple_speech"
    @Published var summaryEngine: String = "mock"
    @Published var fullyLocalMode: Bool = true
}
