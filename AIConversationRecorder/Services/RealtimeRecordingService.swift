import Foundation
import AVFoundation
import Speech

struct LiveTranscriptEntry: Identifiable {
    let id = UUID()
    let speaker: String
    let text: String
}

@MainActor
class RealtimeRecordingService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioLevels: [Float] = Array(repeating: 0.05, count: 30)
    @Published var liveTranscript: [LiveTranscriptEntry] = []

    private let audioEngine = AVAudioEngine()
    private var audioFile: AVAudioFile?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var outputURL: URL?
    private var speakerIndex = 0
    private let speakers = ["話者A", "話者B", "話者C"]

    func requestPermissions() async {
        _ = await AVAudioApplication.requestRecordPermission()
        _ = await withCheckedContinuation { (cont: CheckedContinuation<SFSpeechRecognizerAuthorizationStatus, Never>) in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
    }

    func startRecording() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("rec_\(Int(Date().timeIntervalSince1970)).caf")
        outputURL = url

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        do {
            audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
        } catch { return }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        startRecognitionTask()

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            try? self?.audioFile?.write(from: buffer)
            self?.recognitionRequest?.append(buffer)
            self?.updateLevels(buffer: buffer)
        }

        try? audioEngine.start()
        isRecording = true
    }

    private func startRecognitionTask() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable,
              let request = recognitionRequest else { return }

        let speaker = speakers[speakerIndex % speakers.count]
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, _ in
            guard let self, let result else { return }
            let text = result.bestTranscription.formattedString
            Task { @MainActor in
                if let idx = self.liveTranscript.indices.last,
                   self.liveTranscript[idx].speaker == speaker {
                    self.liveTranscript[idx] = LiveTranscriptEntry(speaker: speaker, text: text)
                } else {
                    self.liveTranscript.append(LiveTranscriptEntry(speaker: speaker, text: text))
                }
                if result.isFinal || text.count > 45 {
                    self.speakerIndex += 1
                    self.restartRecognition()
                }
            }
        }
    }

    private func restartRecognition() {
        recognitionTask?.cancel()
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        startRecognitionTask()
    }

    func pauseRecording() {
        audioEngine.pause()
    }

    func stopRecording() -> URL? {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        audioFile = nil
        return outputURL
    }

    private func updateLevels(buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let n = Int(buffer.frameLength)
        guard n > 0 else { return }
        let sum = (0..<n).reduce(0.0) { $0 + Double(data[$1] * data[$1]) }
        let rms = Float(sqrt(sum / Double(n)))
        let normalized = min(rms * 10, 1.0)
        Task { @MainActor in
            self.audioLevels.removeFirst()
            self.audioLevels.append(normalized)
        }
    }
}
