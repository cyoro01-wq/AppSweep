import Foundation

class SpeakerDiarizationService {
    private let speakers = ["話者A", "話者B", "話者C"]

    func diarize(segments: [TranscriptSegment]) async -> [TranscriptSegment] {
        return segments.enumerated().map { i, seg in
            var updated = seg
            if seg.speakerName == "未分類" || seg.speakerName.isEmpty {
                updated.speakerName = speakers[i % speakers.count]
            }
            return updated
        }
    }
}
