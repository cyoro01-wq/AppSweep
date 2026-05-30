import Foundation

struct ConversationAnalysis: Codable {
    var topics: [String]
    var emotions: Emotions
    var speakerStats: [SpeakerStat]
    var keyPoints: [String]

    struct Emotions: Codable {
        var positive: Double
        var neutral: Double
        var negative: Double
    }

    struct SpeakerStat: Codable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var duration: Double
        var wordCount: Int
    }
}
