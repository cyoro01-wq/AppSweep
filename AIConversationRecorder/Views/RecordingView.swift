import SwiftUI

struct RecordingView: View {
    @StateObject private var service = RealtimeRecordingService()
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var elapsedTime: Double = 0
    @State private var ticker: Timer?
    @State private var laps: [Double] = []
    @State private var savedURL: URL?
    @State private var navigateToProcessing = false

    var body: some View {
        Group {
            if service.isRecording {
                recordingView
            } else {
                idleView
            }
        }
        .navigationTitle("録音")
        .navigationBarTitleDisplayMode(.inline)
        .task { await service.requestPermissions() }
        .navigationDestination(isPresented: $navigateToProcessing) {
            ProcessingView(audioURL: savedURL) { record in
                homeViewModel.add(record)
            }
        }
    }

    // MARK: Idle
    var idleView: some View {
        VStack(spacing: 32) {
            Spacer()
            Button { startRecording() } label: {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.12)).frame(width: 140, height: 140)
                    Circle().fill(Color.blue).frame(width: 100, height: 100)
                    Image(systemName: "mic.fill").font(.system(size: 44)).foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            Text("録音開始").font(.title2.bold())
            Text("タップして会話の録音を開始します")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: Recording
    var recordingView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Circle().fill(.red).frame(width: 10, height: 10)
                Text("録音中").font(.subheadline.bold()).foregroundStyle(.red)
            }
            .padding(.top, 16)

            Text(TimeFormatter.formatLong(elapsedTime))
                .font(.system(size: 52, design: .monospaced).bold())

            WaveformView(levels: service.audioLevels)
                .frame(height: 60)
                .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(service.liveTranscript) { entry in
                            LiveTranscriptRow(entry: entry).id(entry.id)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 180)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .onChange(of: service.liveTranscript.count) { _ in
                    if let last = service.liveTranscript.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            Spacer()

            HStack(spacing: 28) {
                ControlButton(icon: "pause.fill", label: "一時停止", size: 56, color: .orange) {
                    service.pauseRecording()
                }
                ControlButton(icon: "stop.fill", label: "停止", size: 68, color: .red) {
                    savedURL = service.stopRecording()
                    stopTicker()
                    navigateToProcessing = true
                }
                ControlButton(icon: "flag.fill", label: "ラップ", size: 56, color: .blue) {
                    laps.append(elapsedTime)
                }
            }
            .padding(.bottom, 32)
        }
    }

    private func startRecording() {
        service.startRecording()
        elapsedTime = 0
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }
}

// MARK: - Subviews

struct WaveformView: View {
    let levels: [Float]
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<30, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blue)
                    .frame(width: 4,
                           height: CGFloat(levels.indices.contains(i) ? max(4, levels[i] * 60) : 4))
                    .animation(.easeInOut(duration: 0.1),
                               value: levels.indices.contains(i) ? levels[i] : 0)
            }
        }
    }
}

struct LiveTranscriptRow: View {
    let entry: LiveTranscriptEntry
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(entry.speaker)
                .font(.caption.bold()).foregroundStyle(.blue).frame(width: 44)
            Text(entry.text).font(.subheadline)
        }
    }
}

struct ControlButton: View {
    let icon: String
    let label: String
    let size: CGFloat
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay {
                        Image(systemName: icon)
                            .font(.system(size: size * 0.35))
                            .foregroundStyle(color)
                    }
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
