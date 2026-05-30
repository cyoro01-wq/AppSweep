import Foundation

protocol TranscriptionService {
    func transcribe(audioURL: URL) async throws -> [TranscriptSegment]
}
