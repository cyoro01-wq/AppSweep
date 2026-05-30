import SwiftUI

struct RecordsListView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        Group {
            if homeViewModel.records.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60)).foregroundStyle(.secondary)
                    Text("記録がありません").font(.headline)
                    Text("録音すると記録が表示されます")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(homeViewModel.records) { record in
                        NavigationLink {
                            ResultView(record: record) { updated in
                                homeViewModel.update(updated)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.title).font(.headline)
                                HStack {
                                    Text(record.date, style: .date)
                                    Text("·")
                                    Text(TimeFormatter.format(record.totalDuration))
                                }
                                .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { homeViewModel.delete(at: $0) }
                }
            }
        }
        .navigationTitle("記録一覧")
    }
}
