import Foundation

struct JarvisReply: Decodable {
    let reply: String
}

struct TTSPayload: Decodable {
    let audioBase64: String
    let mimeType: String?
}

final class JarvisAPIClient {
    // Replace with your actual endpoint.
    private let chatEndpoint = URL(string: "http://127.0.0.1:8787/api/watch-chat")!
    private let ttsEndpoint = URL(string: "http://127.0.0.1:8787/api/watch-tts")!

    // Optional: if your backend requires x-api-key
    private let apiKey: String? = nil

    func send(text: String) async throws -> String {
        var request = URLRequest(url: chatEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }

        let payload: [String: String] = [
            "text": text,
            "source": "pitboy-watch"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw NSError(domain: "JarvisAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Server error"])
        }

        if let decoded = try? JSONDecoder().decode(JarvisReply.self, from: data) {
            return decoded.reply
        }

        return String(data: data, encoding: .utf8) ?? "No response"
    }

    func synthesize(text: String) async throws -> (data: Data, mimeType: String?) {
        var request = URLRequest(url: ttsEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey, !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }

        let payload: [String: String] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw NSError(domain: "JarvisAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: "TTS server error"])
        }

        let decoded = try JSONDecoder().decode(TTSPayload.self, from: data)
        guard let audioData = Data(base64Encoded: decoded.audioBase64) else {
            throw NSError(domain: "JarvisAPI", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid TTS audio payload"])
        }

        return (audioData, decoded.mimeType)
    }
}
