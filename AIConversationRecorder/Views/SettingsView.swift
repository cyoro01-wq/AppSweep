import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            Section("文字起こし") {
                HStack {
                    Label("エンジン", systemImage: "waveform")
                    Spacer()
                    Text(TranscriptionServiceFactory.isWhisperKitAvailable ? "WhisperKit" : "Apple音声認識")
                        .foregroundStyle(.secondary)
                }
                if TranscriptionServiceFactory.isWhisperKitAvailable {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("WhisperKit インストール済み")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text("WhisperKit を追加するには File → Add Package Dependencies から https://github.com/argmaxinc/WhisperKit を追加してください")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("プライバシー") {
                Toggle(isOn: $appState.fullyLocalMode) {
                    Label("完全ローカルモード", systemImage: "lock.fill")
                }
                Text("オンの場合、音声データはデバイス外に送信されません")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Section("データ") {
                HStack {
                    Label("保存場所", systemImage: "folder.fill")
                    Spacer()
                    Text("Documents フォルダ").foregroundStyle(.secondary)
                }
            }

            Section("アプリ情報") {
                HStack {
                    Label("バージョン", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("設定")
    }
}
