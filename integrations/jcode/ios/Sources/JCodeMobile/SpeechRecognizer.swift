import Foundation
import Speech
import AVFoundation

@MainActor
final class SpeechRecognizer: ObservableObject {
    enum State: Equatable {
        case idle
        case requesting
        case recording
        case error(String)
    }

    @Published var state: State = .idle
    @Published var transcript: String = ""

    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    init() {
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    var isRecording: Bool { state == .recording }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            Task { await startRecording() }
        }
    }

    func startRecording() async {
        guard state != .recording else { return }

        state = .requesting

        let speechStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { status in
                cont.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            state = .error("Speech recognition not authorized")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error("Audio session failed")
            return
        }

        guard let recognizer = recognizer, recognizer.isAvailable else {
            state = .error("Speech recognizer unavailable")
            return
        }

        let engine = AVAudioEngine()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true

        self.audioEngine = engine
        self.recognitionRequest = request
        self.transcript = ""

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.cleanupAudio()
                    if self.state == .recording {
                        self.state = .idle
                    }
                }
            }
        }

        do {
            engine.prepare()
            try engine.start()
            state = .recording
        } catch {
            cleanupAudio()
            state = .error("Could not start audio engine")
        }
    }

    func stopRecording() {
        guard state == .recording else { return }
        cleanupAudio()
        state = .idle
    }

    private func cleanupAudio() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
    }
}
