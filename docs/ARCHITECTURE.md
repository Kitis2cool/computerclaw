# ComputerClaw Architecture

## Components

### 1. iPhone app
- SwiftUI UI
- Speech-to-text using Apple's Speech framework
- Text-to-speech using AVSpeechSynthesizer
- URLSession networking to the local backend

### 2. PC backend
- Small HTTP bridge service
- Receives text from the app
- Returns assistant reply
- Later: forwards messages into OpenClaw

### 3. Connectivity
- Home Wi-Fi for local development
- Tailscale later for away-from-home access

## Milestones

### Milestone 1
- Backend running locally
- App sends typed text
- App receives reply

### Milestone 2
- Add microphone capture + transcription

### Milestone 3
- Add spoken replies

### Milestone 4
- Add conversation memory / UI polish

### Milestone 5
- Add Siri Shortcut entry point

## Wake Word Note

A true always-listening custom wake word is difficult on iPhone due to iOS background restrictions.
The practical route is:
1. tap-to-talk
2. Siri Shortcut phrase
3. investigate deeper wake behavior later
