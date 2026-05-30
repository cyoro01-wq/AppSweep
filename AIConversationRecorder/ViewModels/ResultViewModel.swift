import Foundation

class ResultViewModel: ObservableObject {
    @Published var record: ConversationRecord

    init(record: ConversationRecord) {
        self.record = record
    }
}
