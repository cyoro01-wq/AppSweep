import SwiftUI

struct ProcessingView: View {
    let audioURL: URL?
    let onFinish: (ConversationRecord) -> Void

    @StateObject private var viewModel = ProcessingViewModel()
    @State private var navigateToResult = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("AI処理中...")
                .font(.title.bold())

            VStack(spacing: 16) {
                ForEach(viewModel.steps) { step in
                    ProcessingStepRow(step: step)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            Button("キャンセル") { dismiss() }
                .foregroundStyle(.secondary)
                .padding(.bottom)
        }
        .navigationTitle("AI処理")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .task {
            await viewModel.process(audioURL: audioURL)
            navigateToResult = true
        }
        .navigationDestination(isPresented: $navigateToResult) {
            if let record = viewModel.result {
                ResultView(record: record, onSave: onFinish)
            }
        }
    }
}

// MARK: - Step Row

struct ProcessingStepRow: View {
    let step: ProcessingStep
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(step.rowState.rowColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                if step.rowState == .current {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Image(systemName: step.rowState.rowIcon)
                        .font(.subheadline.bold())
                        .foregroundStyle(step.rowState.rowColor)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(step.name).font(.subheadline.bold())
                Text(step.rowState.rowLabel).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

enum RowState: Equatable {
    case waiting, current, done

    var rowColor: Color {
        switch self {
        case .waiting: return .gray
        case .current: return .blue
        case .done:    return .green
        }
    }

    var rowIcon: String {
        switch self {
        case .waiting: return "circle"
        case .current: return "circle.fill"
        case .done:    return "checkmark"
        }
    }

    var rowLabel: String {
        switch self {
        case .waiting: return "待機中"
        case .current: return "実行中..."
        case .done:    return "完了"
        }
    }
}

struct ProcessingStep: Identifiable {
    var id = UUID()
    var name: String
    var rowState: RowState = .waiting
}
