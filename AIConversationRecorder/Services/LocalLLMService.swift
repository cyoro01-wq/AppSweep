import Foundation

class LocalLLMService {
    func summarize(text: String, format: String) async -> String {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "【AI要約】\n\(text.prefix(200))..."
    }

    func analyze(segments: [TranscriptSegment]) async -> ConversationAnalysis {
        try? await Task.sleep(nanoseconds: 500_000_000)
        var dict: [String: Double] = [:]
        for seg in segments { dict[seg.speakerName, default: 0] += seg.duration }
        let stats = dict.map { name, dur in
            ConversationAnalysis.SpeakerStat(name: name, duration: dur, wordCount: Int(dur * 3))
        }.sorted { $0.duration > $1.duration }

        return ConversationAnalysis(
            topics: ["会話内容", "主要トピック"],
            emotions: ConversationAnalysis.Emotions(positive: 0.6, neutral: 0.3, negative: 0.1),
            speakerStats: stats,
            keyPoints: ["重要ポイント1", "重要ポイント2"]
        )
    }
}
