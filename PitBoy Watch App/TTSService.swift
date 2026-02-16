import Foundation
import AVFoundation

final class TTSService {
    private let synth = AVSpeechSynthesizer()

    func speak(_ text: String) {
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-ZA") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0

        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }
}
