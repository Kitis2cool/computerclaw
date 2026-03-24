import Foundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""

    func requestAuthorization() async {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { _ in
                continuation.resume()
            }
        }
    }

    // Placeholder for real transcription pipeline.
    // Milestone 1 uses typed input first.
}
