import Foundation
import AVFoundation
import Combine

@MainActor
final class PitBoyViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var responseText: String = ""
    @Published var isListening = false
    @Published var isSending = false
    @Published var errorMessage: String?

    private let speechService = SpeechService()
    private let ttsService = TTSService()
    private let api = JarvisAPIClient()

    var statusText: String {
        if isSending { return "UPLINK: SENDING…" }
        if isListening { return "DICTATION: ACTIVE" }
        return "READY"
    }

    func toggleListening() {
        guard !isListening else { return }

        errorMessage = nil
        isListening = true

        speechService.startListening(
            onPartial: { [weak self] text in
                self?.transcript = text
            },
            onError: { [weak self] error in
                self?.errorMessage = error.localizedDescription
            },
            onStopped: { [weak self] in
                self?.isListening = false
            }
        )
    }

    func sendTranscript() async {
        let prompt = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        errorMessage = nil
        isSending = true

        do {
            let reply = try await api.send(text: prompt)
            responseText = reply
            ttsService.speak(reply)
        } catch {
            errorMessage = error.localizedDescription
        }

        isSending = false
    }
}
