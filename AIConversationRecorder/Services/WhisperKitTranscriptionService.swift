import Foundation

#if canImport(WhisperKit)
import WhisperKit

class WhisperKitTranscriptionService: TranscriptionService {
    func transcribe(audioURL: URL) async throws -> [TranscriptSegment] {
        let whisperKit = try await WhisperKit(model: "openai_whisper-base")
        let results = try await whisperKit.transcribe(audioPath: audioURL.path())
        return results.flatMap { $0.segments }.map { seg in
            TranscriptSegment(
                speakerName: "未分類",
                startTime: Double(seg.start),
                endTime: Double(seg.end),
                text: seg.text.trimmingCharacters(in: .whitespaces)
            )
        }
    }
}
#else
class WhisperKitTranscriptionService: TranscriptionService {
    func transcribe(audioURL: URL) async throws -> [TranscriptSegment] {
        return try await AppleSpeechTranscriptionService().transcribe(audioURL: audioURL)
    }
}
#endif
