import Foundation
import Speech
import AVFoundation

class AppleSpeechTranscriptionService: TranscriptionService {
    func transcribe(audioURL: URL) async throws -> [TranscriptSegment] {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "Speech", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "音声認識が利用できません"])
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false

        return try await withCheckedThrowingContinuation { cont in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    cont.resume(throwing: error)
                    return
                }
                guard let result, result.isFinal else { return }

                let segs = result.bestTranscription.segments
                let endTime = segs.last.map { Double($0.timestamp) + Double($0.duration) } ?? 0
                let segment = TranscriptSegment(
                    speakerName: "話者A",
                    startTime: 0,
                    endTime: endTime,
                    text: result.bestTranscription.formattedString
                )
                cont.resume(returning: [segment])
            }
        }
    }
}
