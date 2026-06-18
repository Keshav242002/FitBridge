# FitBridge

**FitBridge** is a local-first fitness coaching platform built with Flutter, enabling seamless communication between trainers and members without relying on a traditional cloud backend.

The platform consists of two independent Flutter applications:

* **Trainer App** — designed for fitness coaches to manage sessions, communicate with members, and conduct live consultations.
* **Member App (Guru)** — designed for fitness members to schedule sessions, communicate with trainers, and participate in live coaching calls.

A lightweight Node.js server acts as a local event bus and token provider, enabling real-time communication, scheduling workflows, video calls, and session tracking while keeping the architecture simple and self-contained.

---

## Key Features

### Real-Time Chat

* Instant messaging between trainer and member
* Message persistence through local server storage
* Lightweight event-bus architecture
* Reliable polling-based synchronization

### Session Scheduling

* Schedule coaching sessions
* Accept or reject requests
* Conflict validation and prevention
* Shared session timeline

### HD Video Calls

* Powered by 100ms
* Secure token-based room access
* Join and leave workflows
* Call lifecycle management
* Automatic session tracking

### Session Logging

* Session duration tracking
* Attendance records
* Trainer notes
* Member feedback and ratings

### Local-First Architecture

* No cloud backend required
* Single Node.js service for communication and token management
* Easy local deployment
* Ideal for development, experimentation, and learning distributed app architecture

---

## Technology Stack

### Frontend

* Flutter 3.x
* Dart 3.x
* BLoC State Management
* Shared Dart Package Architecture

### Backend

* Node.js
* Express
* Event-Bus Pattern
* REST APIs

### Communication

* HTTP Polling
* 100ms Video SDK

---

## Architecture Overview

```text
┌──────────────────┐
│   Trainer App    │
└────────┬─────────┘
         │
         │ HTTP
         │
┌────────▼─────────┐
│  Node.js Server  │
│ Event Bus + API  │
│ Token Provider   │
└────────┬─────────┘
         │
         │ HTTP
         │
┌────────▼─────────┐
│    Member App    │
└──────────────────┘

          │
          ▼
      100ms SDK
    Video Sessions
```

The Node.js service acts as:

* Event bus
* Message broker
* Scheduling coordinator
* Session log manager
* 100ms token issuer

No external database or cloud infrastructure is required for local development.

---

## Project Structure

```text
fitbridge/
├── README.md
├── ARCHITECTURE.md
├── DECISIONS.md
├── DEMO_SCRIPT.md
├── token_server/
├── shared/
├── guru_app/
└── trainer_app/
```

### Shared Package

The shared package contains reusable business logic, models, services, widgets, and feature modules used by both applications.

```text
shared/
├── models/
├── services/
├── features/
├── widgets/
├── utils/
└── test/
```

---

## Getting Started

### Prerequisites

| Tool           | Version   |
| -------------- | --------- |
| Flutter        | 3.x       |
| Dart           | 3.x       |
| Node.js        | 20+       |
| npm            | 9+        |
| Android Studio | Hedgehog+ |
| Xcode          | 15+       |

---

## Running the Token Server

```bash
cd token_server
cp .env.example .env
npm install
npm start
```

Server starts on:

```text
http://localhost:8787
```

Expected output:

```text
[SERVER] FitBridge token server running on :8787
```

---

## Running the Member App

```bash
cd guru_app
flutter pub get

flutter run \
--dart-define=API_BASE_URL=http://10.0.2.2:8787
```

### Simulator Notes

Android Emulator:

```text
http://10.0.2.2:8787
```

iOS Simulator:

```text
http://localhost:8787
```

Physical Device:

```text
http://<host-lan-ip>:8787
```

---

## Running the Trainer App

```bash
cd trainer_app
flutter pub get

flutter run \
--dart-define=API_BASE_URL=http://10.0.2.2:8787
```

Run both applications simultaneously to experience the complete trainer-member workflow.

---

## Demo Users

### Trainer

```text
Email: aarav@fitbridge.local
Password: any
```

### Member

```text
Name: DK
```

Configured automatically during onboarding.

---

## Testing

Run shared package tests:

```bash
cd shared
flutter test
```

Current test coverage includes:

* Message validation
* Schedule validation
* Session duration calculations

---

## Design Decisions

Key architectural decisions are documented in:

* ARCHITECTURE.md
* DECISIONS.md

Topics include:

* BLoC architecture
* Shared package strategy
* Local-first communication model
* 100ms integration lifecycle
* Session logging design

---

## Current Limitations

* Chat uses polling (~500ms refresh interval)
* Single trainer-member workflow in current version
* Manual LAN configuration required for physical devices
* Limited token retry handling during long-running calls

These trade-offs were intentionally chosen to keep the architecture simple and focused on core coaching workflows.

---

## Future Roadmap

* Server-Sent Events (SSE)
* Push notifications
* Image and file sharing
* Offline message queue
* Multi-trainer support
* Multi-member support
* Dark mode
* Session exports
* Analytics dashboard
* Cloud synchronization option

---

## License

This project was created as a personal learning project to explore:

* Flutter application architecture
* Shared package design
* Local-first systems
* Real-time communication workflows
* Video calling integrations

It is intended for educational and experimentation purposes only and is **not intended for production use**.
