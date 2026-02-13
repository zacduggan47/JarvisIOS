import Foundation
import Speech
import AVFoundation
import Combine
import UIKit

@MainActor
final class VoiceInputManager: ObservableObject {
    enum State: Equatable {
        case idle
        case requestingPermissions
        case listening
        case finishing
        case error(String)
        case success(String)
    }

    @Published var state: State = .idle
    @Published var partialText: String = ""
    @Published var finalText: String = ""

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer

    private let hapticsStart = UIImpactFeedbackGenerator(style: .rigid)
    private let hapticsStop = UIImpactFeedbackGenerator(style: .soft)

    init(localeIdentifier: String = Locale.current.identifier) {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)) ?? SFSpeechRecognizer()!
    }

    func updateLocale(_ identifier: String) {
        if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: identifier)) {
            self.speechRecognizer = recognizer
        }
    }

    func requestPermissions() async -> Bool {
        state = .requestingPermissions
        let micGranted: Bool = await withCheckedContinuation { cont in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
        await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { _ in cont.resume(returning: ()) }
        }
        let granted = micGranted && (SFSpeechRecognizer.authorizationStatus() == .authorized)
        if !granted { state = .error("Microphone or Speech permission denied") }
        return granted
    }

    func startListening(autoPunctuation: Bool = true) async {
        guard await requestPermissions() else { return }
        stop() // ensure clean state

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        if #available(iOS 16.0, *) {
            recognitionRequest?.requiresOnDeviceRecognition = false
            recognitionRequest?.taskHint = .dictation
        }

        let inputNode = audioEngine.inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            state = .error("Audio engine start failed: \(error.localizedDescription)")
            return
        }

        hapticsStart.impactOccurred()
        state = .listening

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                self.partialText = result.bestTranscription.formattedString
                if result.isFinal {
                    self.finalText = result.bestTranscription.formattedString
                    self.state = .success(self.finalText)
                }
            }
            if let error = error {
                self.state = .error(error.localizedDescription)
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionRequest?.endAudio()
        }
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        partialText = ""
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        if case .listening = state {
            hapticsStop.impactOccurred()
            state = .finishing
        }
    }
}
