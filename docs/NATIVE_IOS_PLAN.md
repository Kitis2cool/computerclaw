# Native iPhone App Plan (Future)

## Objective
Build a native SwiftUI iPhone app for ComputerClaw once a Cloud Mac is available.

## App Structure

### Core files
- `ComputerClawApp.swift`
- `ContentView.swift`
- `APIClient.swift`
- `Models.swift`
- `SpeechRecognizer.swift` (later)
- `SpeechSynthesizer.swift` (later)

## v1 Native Scope
- Text-only chat UI
- POST to backend `/ask`
- Render reply bubble
- Status indicator
- Dark theme

## Networking
Backend contract:

Request:
```json
{ "message": "hello" }
```

Response:
```json
{ "reply": "hi" }
```

Preferred backend target:
- Tailscale IP or MagicDNS name for Riley's PC

## Native v1 Build Order
1. Build static SwiftUI chat layout
2. Wire typed message sending
3. Show assistant reply
4. Add loading/error state
5. Add microphone input later
6. Add spoken replies later

## Native UI Style
- dark glass / minimal
- private sidekick feel
- avoid corporate productivity app styling
- one-thread conversation

## Native Permissions Later
- microphone
- speech recognition

## Notes
The web app should be treated as the proving ground for interaction design before porting to SwiftUI.
