# Jarvis iOS App

A personal AI assistant built with SwiftUI that connects to an OpenClaw Gateway backend.

## Features
- SwiftUI chat interface with message bubbles
- Async message sending with loading/error handling
- Gateway client for posting conversation history and receiving replies
- XcodeGen-powered project generation

## Project Structure
```
Sources/JarvisIOS/
├── App/
│   └── JarvisApp.swift
├── Features/Chat/
│   ├── ChatView.swift
│   └── ChatViewModel.swift
├── Models/
│   └── ChatMessage.swift
├── Networking/
│   └── GatewayClient.swift
└── Resources/
    └── Info.plist
```


## Getting Started

### Prerequisites
- Xcode 16+
- XcodeGen (`brew install xcodegen`)


### Configure
Optionally set a custom gateway URL before running:

```bash
export OPENCLAW_GATEWAY_URL="https://your-gateway.example/v1/chat"
```

If not set, the app defaults to:

```text
https://api.openclaw.dev/v1/chat
```

### Build
```bash
xcodegen generate
open JarvisIOS.xcodeproj
```


## License

MIT
