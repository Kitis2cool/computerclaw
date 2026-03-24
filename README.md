<<<<<<< HEAD
# ComputerClaw

Native iPhone assistant app in SwiftUI with eventual wake-word support.

## Goals

- Native iPhone app in Swift/SwiftUI
- Tap-to-talk first
- Spoken replies
- Local PC bridge/backend
- Tailscale-friendly connectivity
- Eventual Siri / wake-word adjacent flow

## Project Structure

- `backend/` — local bridge service running on the PC
- `ios/ComputerClaw/` — SwiftUI app starter files
- `docs/` — architecture and next steps

## First Milestone

1. Run the backend locally on the PC
2. Send a test message from the iPhone app
3. Receive a text reply
4. Add speech input
5. Add spoken output

## Backend Plan

The backend exposes a simple HTTP endpoint:

- `POST /ask`

Request:

```json
{ "message": "hello" }
```

Response:

```json
{ "reply": "hi" }
```

## iOS Plan

Version 1:
- text + mic UI
- send message to backend
- display reply
- speak reply aloud

Version 2:
- conversation history
- polished UI
- Siri Shortcut integration

Version 3:
- investigate wake-word options

## Next Steps

- Install Node.js if needed for backend
- Open the `ios/ComputerClaw` folder in Xcode
- Edit `APIClient.swift` to point at your backend host/Tailscale IP
- Build Milestone 1 before worrying about wake word
=======
# flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
>>>>>>> 7439262a25504ac5130471dff21d7bb4348a8d95
