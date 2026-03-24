import SwiftUI

struct ContentView: View {
    @State private var input: String = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var autoSpeak = true

    private let api = APIClient()
    private let speaker = SpeechSynthesizer()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            HStack {
                                if message.role == .assistant { Spacer(minLength: 24) }
                                Text(message.text)
                                    .padding(12)
                                    .background(message.role == .user ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                if message.role == .user { Spacer(minLength: 24) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Toggle("Speak replies out loud", isOn: $autoSpeak)

                HStack(spacing: 12) {
                    TextField("Say or type something...", text: $input, axis: .vertical)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: isLoading ? "hourglass" : "arrow.up.circle.fill")
                            .font(.system(size: 28))
                    }
                    .disabled(isLoading || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Button {
                    // Placeholder mic button for Milestone 1.
                } label: {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 64))
                }
                .padding(.bottom, 8)
            }
            .padding()
            .navigationTitle("ComputerClaw")
        }
    }

    @MainActor
    private func send() async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(.init(role: .user, text: trimmed))
        input = ""
        isLoading = true

        do {
            let reply = try await api.ask(trimmed)
            messages.append(.init(role: .assistant, text: reply))
            if autoSpeak {
                speaker.speak(reply)
            }
        } catch {
            messages.append(.init(role: .assistant, text: "Error: \(error.localizedDescription)"))
        }

        isLoading = false
    }
}

#Preview {
    ContentView()
}
