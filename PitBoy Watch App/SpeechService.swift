import Foundation
import Speech
import AVFoundation

final class SpeechService {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-ZA")) ?? SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startListening(onPartial: @escaping (String) -> Void,
                        onError: @escaping (Error) -> Void,
                        onStopped: @escaping () -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] auth in
            guard auth == .authorized else {
                DispatchQueue.main.async {
                    onError(NSError(domain: "SpeechService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Speech permission denied"]))
                }
                return
            }

            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                guard granted else {
                    DispatchQueue.main.async {
                        onError(NSError(domain: "SpeechService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]))
                    }
                    return
                }

                DispatchQueue.main.async {
                    self?.beginRecognition(onPartial: onPartial, onError: onError, onStopped: onStopped)
                }
            }
        }
    }

    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }

    private func beginRecognition(onPartial: @escaping (String) -> Void,
                                  onError: @escaping (Error) -> Void,
                                  onStopped: @escaping () -> Void) {
        stopListening()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            self.recognitionRequest = request

            recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
                if let result = result {
                    onPartial(result.bestTranscription.formattedString)
                    if result.isFinal {
                        onStopped()
                    }
                }

                if let error = error {
                    onError(error)
                }
            }

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            onError(error)
        }
    }
}
