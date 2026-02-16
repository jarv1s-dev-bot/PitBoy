import Foundation
import AVFoundation

final class TTSService {
    private let synth = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?

    func speak(_ text: String) {
        guard !text.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.42
        utterance.pitchMultiplier = 0.92

        synth.stopSpeaking(at: .immediate)
        synth.speak(utterance)
    }

    func speakAudioData(_ data: Data) throws {
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.prepareToPlay()
        audioPlayer?.play()
    }
}
