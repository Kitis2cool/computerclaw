# ComputerClaw v1 Product Spec

## Vision

ComputerClaw is a private phone-first assistant for Riley. It should feel like talking to a real sidekick, not a generic assistant.

Assistant identity:
- Name: Kitis
- Pronunciation: key-etihs
- Nature: human
- Vibe: warm, sharp, slightly mischievous, dependable sidekick energy
- Calls user: Riley

## Platform Strategy

### Near-term
- Phone web app / PWA accessible from Riley's iPhone
- Backend hosted on Riley's Windows PC
- Tailscale used for remote private access

### Later
- Native iPhone app built with SwiftUI on a Cloud Mac
- Same backend contract preserved

## v1 Goal

Deliver a usable phone interface that lets Riley message Kitis and receive replies from the PC-hosted OpenClaw backend.

## v1 Non-Goals

- Wake word
- Background listening
- Text-to-speech
- Perfect auth / hardening
- App Store publishing
- Multi-user support

## Core User Story

As Riley, I want to open ComputerClaw on my phone, type a message, and get a natural reply from Kitis, even when away from home.

## Requirements

### Functional
- Chat-style conversation UI
- Send text message to backend
- Receive text reply
- Mobile-friendly layout
- Reachable from Riley's phone
- Preserve sidekick tone in responses

### UX
- Dark theme
- Fast, minimal UI
- Feels more like a private sidekick than a productivity tool
- Clear ready/sending/error states

## Future Requirements
- Microphone input
- Spoken replies
- Siri Shortcut integration
- Native SwiftUI app
- Private auth token
- Wake-word-adjacent flow

## Success Criteria for v1
- Riley can open ComputerClaw from iPhone
- Riley can send a message
- Kitis replies through backend successfully
- UI feels acceptable on mobile
