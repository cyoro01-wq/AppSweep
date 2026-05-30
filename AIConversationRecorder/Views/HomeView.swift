import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var showFileImporter = false
    @State private var importedURL: URL?
    @State private var navigateToProcessing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI会話記録")
                            .font(.largeTitle.bold())
                        Text("音声を記録・分析・要約")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { appState.selectedTab = 3 } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)

                VStack(spacing: 12) {
                    HomeActionButton(
                        icon: "mic.fill", color: .blue,
                        title: "新しく録音する",
                        subtitle: "マイクで会話を録音します"
                    ) { appState.selectedTab = 1 }

                    HomeActionButton(
                        icon: "folder.fill", color: .green,
                        title: "音声ファイルを読み込む",
                        subtitle: "既存の音声ファイルを分析します"
                    ) { showFileImporter = true }

                    HomeActionButton(
                        icon: "doc.text.fill", color: .purple,
                        title: "過去の記録を見る",
                        subtitle: "保存された会話記録を確認します"
                    ) { appState.selectedTab = 2 }
                }
                .padding(.horizontal)

                if !homeViewModel.records.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近の記録")
                                .font(.headline)
                            Spacer()
                            Button("すべて見る >") { appState.selectedTab = 2 }
                                .font(.subheadline)
                        }
                        .padding(.horizontal)

                        ForEach(homeViewModel.records.prefix(3)) { record in
                            HomeRecordRow(record: record)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .navigationBarHidden(true)
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.audio]) { result in
            if case .success(let url) = result {
                importedURL = url
                navigateToProcessing = true
            }
        }
        .navigationDestination(isPresented: $navigateToProcessing) {
            ProcessingView(audioURL: importedURL) { record in
                homeViewModel.add(record)
                appState.selectedTab = 2
            }
        }
    }
}

struct HomeActionButton: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

struct HomeRecordRow: View {
    let record: ConversationRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.title).font(.subheadline.bold())
                Text(record.date, style: .date)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
