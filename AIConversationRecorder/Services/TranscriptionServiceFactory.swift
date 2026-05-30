import Foundation

struct TranscriptionServiceFactory {
    static var isWhisperKitAvailable: Bool {
        #if canImport(WhisperKit)
        return true
        #else
        return false
        #endif
    }

    static func make(engine: String) -> TranscriptionService {
        if isWhisperKitAvailable {
            return WhisperKitTranscriptionService()
        }
        return AppleSpeechTranscriptionService()
    }
}
