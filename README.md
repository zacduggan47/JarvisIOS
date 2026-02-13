# Jarvis iOS App

A personal AI assistant built with SwiftUI. Connects to OpenClaw Gateway.

## Features

- 🎯 Personal onboarding (Memory + Soul questions)
- 💬 Chat interface with AI
- 🔌 WebSocket connection to Gateway
- 🔐 Keychain token storage
- 📧 Nylas integration (Gmail, Calendar, Contacts)
- 🟠 Orange brand theme

## Getting Started

### Prerequisites

- Xcode 15+
- XcodeGen (`brew install xcodegen`)

### Build

```bash
# Generate Xcode project
xcodegen generate

# Open in Xcode
open JarvisIOS.xcodeproj

# Or build from terminal
xcodebuild -project JarvisIOS.xcodeproj -scheme JarvisIOS -destination 'platform=iOS Simulator,name=iPhone 17' build
```

## Project Structure

```
JarvisIOS/
├── App/
│   ├── JarvisApp.swift      # App entry point
│   └── Info.plist          # App configuration
├── Models/
│   └── ChatMessage.swift   # Data models
├── ViewModels/
│   └── ChatViewModel.swift # Chat state management
├── Views/
│   ├── ContentView.swift  # Main views
│   └── ChatView.swift     # Chat interface
├── Services/
│   └── WebSocketManager.swift
└── project.yml            # XcodeGen config
```

## Configuration

Set your Gateway URL in `ChatViewModel.swift`:

```swift
init(gatewayURL: String = "wss://your-gateway.com/ws")
```

## License

MIT
