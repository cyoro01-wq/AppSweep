import SwiftUI

struct ResultView: View {
    let record: ConversationRecord
    let onSave: (ConversationRecord) -> Void

    @State private var selectedTab = 0
    @StateObject private var audioPlayer = AudioPlayerViewModel()
    @State private var editedRecord: ConversationRecord

    init(record: ConversationRecord, onSave: @escaping (ConversationRecord) -> Void) {
        self.record = record
        self.onSave = onSave
        self._editedRecord = State(initialValue: record)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("文字起こし").tag(0)
                Text("話者").tag(1)
                Text("分析").tag(2)
                Text("要約").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            TabView(selection: $selectedTab) {
                TranscriptTab(segments: record.transcriptSegments, audioPlayer: audioPlayer).tag(0)
                SpeakersTab(record: record).tag(1)
                AnalysisTab(analysis: record.analysis).tag(2)
                SummaryTab(record: $editedRecord).tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle(record.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存") { onSave(editedRecord) }
            }
        }
        .task {
            if let url = record.audioFileURL { audioPlayer.load(url: url) }
        }
    }
}

// MARK: - Transcript Tab

struct TranscriptTab: View {
    let segments: [TranscriptSegment]
    @ObservedObject var audioPlayer: AudioPlayerViewModel

    private let colors: [Color] = [.blue, .green, .orange, .purple, .red]
    func color(for name: String) -> Color { colors[abs(name.hashValue) % colors.count] }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(segments) { seg in
                        SegmentCard(segment: seg, color: color(for: seg.speakerName))
                    }
                }
                .padding()
                .padding(.bottom, audioPlayer.duration > 0 ? 80 : 0)
            }
            if audioPlayer.duration > 0 {
                AudioPlayerBar(player: audioPlayer)
                    .padding()
                    .background(.regularMaterial)
            }
        }
    }
}

struct SegmentCard: View {
    let segment: TranscriptSegment
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(segment.speakerName)
                    .font(.caption.bold()).foregroundStyle(color)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(color.opacity(0.15)).clipShape(Capsule())
                Text(TimeFormatter.format(segment.startTime))
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Button { UIPasteboard.general.string = segment.text } label: {
                    Image(systemName: "doc.on.doc").font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(segment.text).font(.subheadline)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AudioPlayerBar: View {
    @ObservedObject var player: AudioPlayerViewModel
    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.3)).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2).fill(Color.blue)
                        .frame(width: geo.size.width * CGFloat(player.progress), height: 4)
                }
                .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                    player.seek(to: v.location.x / geo.size.width)
                })
            }
            .frame(height: 4)

            HStack {
                Text(TimeFormatter.format(player.currentTime)).font(.caption.monospacedDigit())
                Spacer()
                Button { player.togglePlay() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").font(.title2)
                }
                Spacer()
                Button { player.cycleRate() } label: {
                    Text("\(player.playbackRate, specifier: "%.2g")x")
                        .font(.caption.bold()).padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.quaternary).clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Speakers Tab

struct SpeakersTab: View {
    let record: ConversationRecord
    private let colors: [Color] = [.blue, .green, .orange, .purple, .red]

    var stats: [ConversationAnalysis.SpeakerStat] { record.analysis?.speakerStats ?? [] }
    var total: Double { stats.map(\.duration).reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if stats.isEmpty {
                    Text("話者データがありません").foregroundStyle(.secondary).padding()
                } else {
                    DonutChart(stats: stats, total: total, colors: colors)
                        .frame(height: 220).padding()
                    VStack(spacing: 12) {
                        ForEach(stats.indices, id: \.self) { i in
                            SpeakerDetailRow(stat: stats[i], color: colors[i % colors.count], total: total)
                        }
                    }.padding(.horizontal)
                }
            }
        }
    }
}

struct DonutChart: View {
    let stats: [ConversationAnalysis.SpeakerStat]
    let total: Double
    let colors: [Color]
    var body: some View {
        ZStack {
            ForEach(stats.indices, id: \.self) { i in
                let start = stats.prefix(i).map { $0.duration / total }.reduce(0, +)
                let end = start + stats[i].duration / total
                Circle().trim(from: start, to: end)
                    .stroke(colors[i % colors.count], lineWidth: 36)
                    .rotationEffect(.degrees(-90))
            }
            Text("\(stats.count)\n話者").font(.headline).multilineTextAlignment(.center)
        }
    }
}

struct SpeakerDetailRow: View {
    let stat: ConversationAnalysis.SpeakerStat
    let color: Color
    let total: Double
    var pct: Int { total > 0 ? Int(stat.duration / total * 100) : 0 }
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 12, height: 12)
            Text(stat.name).font(.subheadline.bold())
            Spacer()
            Text("\(pct)%").font(.subheadline).foregroundStyle(.secondary)
            Text(TimeFormatter.format(stat.duration)).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Analysis Tab

struct AnalysisTab: View {
    let analysis: ConversationAnalysis?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let a = analysis {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("トピック").font(.headline).padding(.horizontal)
                        TopicChipsView(topics: a.topics).padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("感情分析").font(.headline).padding(.horizontal)
                        EmotionBar(emotions: a.emotions).padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("重要ポイント").font(.headline).padding(.horizontal)
                        ForEach(a.keyPoints, id: \.self) { pt in
                            HStack(alignment: .top, spacing: 8) {
                                Circle().fill(.blue).frame(width: 6, height: 6).padding(.top, 6)
                                Text(pt).font(.subheadline)
                            }.padding(.horizontal)
                        }
                    }
                } else {
                    Text("分析データがありません").foregroundStyle(.secondary).padding()
                }
            }
            .padding(.vertical)
        }
    }
}

struct TopicChipsView: View {
    let topics: [String]
    private let chipColors: [Color] = [.blue, .green, .orange, .purple, .red, .teal]
    let cols = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        LazyVGrid(columns: cols, spacing: 8) {
            ForEach(topics.indices, id: \.self) { i in
                Text(topics[i])
                    .font(.caption.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(chipColors[i % chipColors.count])
                    .clipShape(Capsule())
            }
        }
    }
}

struct EmotionBar: View {
    let emotions: ConversationAnalysis.Emotions
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Color.green).frame(width: geo.size.width * emotions.positive)
                    Rectangle().fill(Color.gray).frame(width: geo.size.width * emotions.neutral)
                    Rectangle().fill(Color.red).frame(width: geo.size.width * emotions.negative)
                }
                .clipShape(Capsule())
            }
            .frame(height: 16)
            HStack {
                Label("\(Int(emotions.positive * 100))%", systemImage: "circle.fill").foregroundStyle(.green).font(.caption)
                Spacer()
                Label("\(Int(emotions.neutral * 100))%", systemImage: "circle.fill").foregroundStyle(.gray).font(.caption)
                Spacer()
                Label("\(Int(emotions.negative * 100))%", systemImage: "circle.fill").foregroundStyle(.red).font(.caption)
            }
        }
    }
}

// MARK: - Summary Tab

struct SummaryTab: View {
    @Binding var record: ConversationRecord
    @State private var generated = false
    @State private var isEditing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !generated && record.summary.isEmpty {
                    summarySelection
                } else {
                    summaryContent
                }
            }
            .padding()
        }
    }

    var summarySelection: some View {
        VStack(spacing: 16) {
            Text("要約形式を選択").font(.headline)
            ForEach(SummaryFormat.allCases, id: \.self) { fmt in
                Button {
                    record.summary = fmt.sampleText
                    generated = true
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(fmt.title).font(.subheadline.bold()).foregroundStyle(.primary)
                            Text(fmt.subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    var summaryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("要約").font(.headline)
                Spacer()
                Button { isEditing.toggle() } label: {
                    Label(isEditing ? "完了" : "編集", systemImage: isEditing ? "checkmark" : "pencil").font(.caption)
                }
                Button { UIPasteboard.general.string = record.summary } label: {
                    Label("コピー", systemImage: "doc.on.doc").font(.caption)
                }
            }
            if isEditing {
                TextEditor(text: $record.summary)
                    .frame(minHeight: 200).padding(8)
                    .background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text(record.summary).font(.subheadline)
                    .padding().background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

enum SummaryFormat: CaseIterable {
    case general, minutes, soap, support, detailed

    var title: String {
        switch self {
        case .general:  return "一般要約"
        case .minutes:  return "議事録形式"
        case .soap:     return "SOAPノート"
        case .support:  return "サポート記録"
        case .detailed: return "詳細要約"
        }
    }

    var subtitle: String {
        switch self {
        case .general:  return "会話の概要を簡潔にまとめます"
        case .minutes:  return "会議の議事録形式でまとめます"
        case .soap:     return "医療・支援向けSOAP形式"
        case .support:  return "支援記録向け形式"
        case .detailed: return "詳細な内容をすべて記録します"
        }
    }

    var sampleText: String {
        switch self {
        case .general:
            return "会話では主にプロジェクトの進捗について議論されました。参加者は現状の課題を共有し、次のステップについて合意しました。"
        case .minutes:
            return "【参加者】話者A、話者B\n\n【議題】\n1. プロジェクト進捗報告\n2. 課題の共有\n\n【決定事項】\n・次回ミーティングを来週開催\n・課題対応担当者を決定"
        case .soap:
            return "S（主観）: 参加者から現状の課題について報告あり。\nO（客観）: 3件の課題が確認された。\nA（評価）: プロジェクトは予定通り進行中。\nP（計画）: 課題を来週までに解決予定。"
        case .support:
            return "【支援内容】プロジェクト進捗の確認と課題解決のサポート\n\n【観察事項】参加者は積極的に議論に参加していた\n\n【次回の支援計画】来週フォローアップを実施"
        case .detailed:
            return "会話の詳細な要約です。話者Aはプロジェクトの進捗について詳しく説明し、話者Bは質問と意見を述べました。"
        }
    }
}
