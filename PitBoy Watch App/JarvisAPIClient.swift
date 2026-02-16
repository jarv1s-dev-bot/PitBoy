import Foundation

struct JarvisReply: Decodable {
    let reply: String
}

final class JarvisAPIClient {
    // Replace with your actual endpoint.
    // Example: https://your-domain.com/api/watch-chat
    private let endpoint = URL(string: "https://example.com/api/watch-chat")!

    // Optional: if your backend requires x-api-key
    private let apiKey: String? = nil

    func send(text: String) async throws -> String {
        var request = URLRequest(url: endpoint)
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

        // Fallback if backend returns plain text
        return String(data: data, encoding: .utf8) ?? "No response"
    }
}
