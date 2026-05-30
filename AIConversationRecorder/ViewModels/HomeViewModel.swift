import Foundation

class HomeViewModel: ObservableObject {
    @Published var records: [ConversationRecord] = []

    private let storageKey = "saved_records"

    init() {
        load()
        if records.isEmpty {
            records = [ConversationRecord.sampleData]
        }
    }

    func add(_ record: ConversationRecord) {
        records.insert(record, at: 0)
        save()
    }

    func update(_ record: ConversationRecord) {
        if let idx = records.firstIndex(where: { $0.id == record.id }) {
            records[idx] = record
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ConversationRecord].self, from: data)
        else { return }
        records = saved
    }
}
