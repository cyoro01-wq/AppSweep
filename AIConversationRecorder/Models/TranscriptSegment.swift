import Foundation

struct TranscriptSegment: Identifiable, Codable {
    var id: UUID = UUID()
    var speakerName: String
    var startTime: Double
    var endTime: Double
    var text: String

    var duration: Double { endTime - startTime }
}
