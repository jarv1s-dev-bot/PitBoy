import Foundation
import WatchKit

@MainActor
final class SpeechService {
    /// Uses native watchOS dictation UI and returns recognized text.
    func startListening(onPartial: @escaping (String) -> Void,
                        onError: @escaping (Error) -> Void,
                        onStopped: @escaping () -> Void) {
        guard let controller = WKExtension.shared().visibleInterfaceController else {
            onError(NSError(domain: "SpeechService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No visible watch interface controller"] ))
            onStopped()
            return
        }

        controller.presentTextInputController(withSuggestions: nil, allowedInputMode: .plain) { results in
            Task { @MainActor in
                defer { onStopped() }

                guard let first = results?.first else { return }

                if let text = first as? String {
                    onPartial(text)
                    return
                }

                // Some dictation modes can return attributed strings.
                if let attributed = first as? NSAttributedString {
                    onPartial(attributed.string)
                    return
                }

                onError(NSError(domain: "SpeechService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Dictation returned unsupported format"]))
            }
        }
    }

    func stopListening() {
        // Dictation controller is managed by watchOS; no-op.
    }
}
