import Foundation

final class APIClient {
    // Replace with your PC LAN IP or Tailscale IP when testing on phone.
    // Example: http://100.89.191.12:8787
    private let baseURL = URL(string: "http://127.0.0.1:8787")!

    func ask(_ message: String) async throws -> String {
        let url = baseURL.appendingPathComponent("ask")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AskRequest(message: message))

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(AskResponse.self, from: data)
        return decoded.reply
    }
}
