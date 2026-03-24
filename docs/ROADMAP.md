# ComputerClaw Roadmap

## Phase 0 - Foundations
Status: mostly done

- [x] Create backend project
- [x] Expose `/ask` endpoint
- [x] Connect backend to OpenClaw local agent flow
- [x] Make phone-reachable web UI
- [x] Establish Kitis identity and tone

## Phase 1 - Phone Web App
Status: in progress

- [x] Mobile-friendly homepage
- [x] Chat UI
- [x] Send/receive text
- [ ] Better error UI
- [ ] Persist conversation locally in browser
- [ ] Add install-to-home-screen guidance
- [ ] Optional PWA manifest/icons

## Phase 2 - Voice Input
- [ ] Add microphone button to web app
- [ ] Use Web Speech API where available
- [ ] Handle unsupported browsers gracefully
- [ ] Auto-fill or auto-send transcript

## Phase 3 - Voice Output
- [ ] Add speak-reply toggle
- [ ] Use browser speech synthesis as first pass
- [ ] Keep output concise for spoken mode

## Phase 4 - Private Access Hardening
- [ ] Add bearer token auth to backend
- [ ] Restrict usage to Riley's phone/app
- [ ] Validate Tailscale-only access path

## Phase 5 - Native iPhone App
- [ ] Use Cloud Mac
- [ ] Create SwiftUI `ComputerClaw` app shell
- [ ] Port API contract to native app
- [ ] Rebuild chat UI in SwiftUI
- [ ] Add native speech input
- [ ] Add native spoken replies

## Phase 6 - Wake Word / Siri Entry
- [ ] Siri Shortcut launch phrase
- [ ] Launch app directly into listen mode
- [ ] Investigate realistic wake-word options on iPhone
