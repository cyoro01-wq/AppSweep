import Foundation

struct ConversationRecord: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var date: Date
    var audioFileURL: URL?
    var transcriptSegments: [TranscriptSegment]
    var summary: String
    var detailedSummary: String
    var minutesSummary: String
    var supportRecordSummary: String
    var soapNote: String
    var analysis: ConversationAnalysis?

    var fullText: String {
        transcriptSegments.map { $0.text }.joined(separator: " ")
    }

    var totalDuration: Double {
        transcriptSegments.last?.endTime ?? 0
    }

    static let sampleData = ConversationRecord(
        id: UUID(),
        title: "チーム会議 2024/01",
        date: Date().addingTimeInterval(-86400),
        audioFileURL: nil,
        transcriptSegments: [
            TranscriptSegment(speakerName: "話者A", startTime: 0, endTime: 5, text: "本日はお集まりいただきありがとうございます。"),
            TranscriptSegment(speakerName: "話者B", startTime: 5, endTime: 12, text: "はい、よろしくお願いします。今日の議題について確認させてください。"),
            TranscriptSegment(speakerName: "話者A", startTime: 12, endTime: 20, text: "まず第一に、プロジェクトの進捗状況を共有したいと思います。"),
        ],
        summary: "チーム会議の議事録です。",
        detailedSummary: "詳細な会議の内容です。",
        minutesSummary: "議事録の要約です。",
        supportRecordSummary: "サポート記録の要約です。",
        soapNote: "SOAP形式のノートです。",
        analysis: ConversationAnalysis(
            topics: ["プロジェクト進捗", "課題共有", "次のステップ"],
            emotions: ConversationAnalysis.Emotions(positive: 0.6, neutral: 0.3, negative: 0.1),
            speakerStats: [
                ConversationAnalysis.SpeakerStat(name: "話者A", duration: 15, wordCount: 45),
                ConversationAnalysis.SpeakerStat(name: "話者B", duration: 10, wordCount: 30)
            ],
            keyPoints: ["プロジェクトは予定通り進行中", "課題は3件あり対応中", "次回は来週を予定"]
        )
    )
}
