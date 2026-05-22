import Foundation
import SwiftUI

@MainActor
class ProcessingViewModel: ObservableObject {
    @Published var steps: [ProcessingStep] = [
        ProcessingStep(name: "文字起こし"),
        ProcessingStep(name: "話者分離"),
        ProcessingStep(name: "会話分析"),
        ProcessingStep(name: "要約作成"),
        ProcessingStep(name: "レポート生成"),
    ]
    @Published var result: ConversationRecord?

    func process(audioURL: URL?) async {
        let service = TranscriptionServiceFactory.make(engine: "apple_speech")

        await setStep(0, state: .current)
        var segments: [TranscriptSegment]
        if let url = audioURL {
            segments = (try? await service.transcribe(audioURL: url)) ?? demoSegments()
        } else {
            segments = demoSegments()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
        }
        await setStep(0, state: .done)

        await setStep(1, state: .current)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        await setStep(1, state: .done)

        await setStep(2, state: .current)
        try? await Task.sleep(nanoseconds: 800_000_000)
        await setStep(2, state: .done)

        await setStep(3, state: .current)
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        await setStep(3, state: .done)

        await setStep(4, state: .current)
        try? await Task.sleep(nanoseconds: 500_000_000)
        await setStep(4, state: .done)

        result = ConversationRecord(
            title: "会話記録 \(Date().formatted(date: .abbreviated, time: .omitted))",
            date: Date(),
            audioFileURL: audioURL,
            transcriptSegments: segments,
            summary: "会話の要約がここに表示されます。",
            detailedSummary: "",
            minutesSummary: "",
            supportRecordSummary: "",
            soapNote: "",
            analysis: ConversationAnalysis(
                topics: ["主要トピック", "議論内容", "決定事項"],
                emotions: ConversationAnalysis.Emotions(positive: 0.6, neutral: 0.3, negative: 0.1),
                speakerStats: speakerStats(from: segments),
                keyPoints: ["重要ポイント1", "重要ポイント2", "重要ポイント3"]
            )
        )
    }

    private func setStep(_ index: Int, state: RowState) async {
        steps[index].rowState = state
    }

    private func demoSegments() -> [TranscriptSegment] {
        [
            TranscriptSegment(speakerName: "話者A", startTime: 0, endTime: 8, text: "本日はお集まりいただきありがとうございます。"),
            TranscriptSegment(speakerName: "話者B", startTime: 8, endTime: 18, text: "はい、よろしくお願いします。"),
            TranscriptSegment(speakerName: "話者A", startTime: 18, endTime: 30, text: "では、議題に入りましょう。"),
        ]
    }

    private func speakerStats(from segments: [TranscriptSegment]) -> [ConversationAnalysis.SpeakerStat] {
        var dict: [String: Double] = [:]
        for seg in segments { dict[seg.speakerName, default: 0] += seg.duration }
        return dict.map { name, dur in
            ConversationAnalysis.SpeakerStat(name: name, duration: dur, wordCount: Int(dur * 3))
        }.sorted { $0.duration > $1.duration }
    }
}
