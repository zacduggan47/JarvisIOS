import SwiftUI
import Combine

struct ChatContainerView: View {
    @ObservedObject var viewModel: ChatViewModel

    @State private var selectedTab: Tab = .chat
    @State private var showSuggestions: Bool = true
    @State private var inputText: String = ""
    @StateObject private var voice = VoiceInputManager()

    enum Tab { case chat, calendar, mood, sounds }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                content
                // Floating mic for Wispr-style capture
                FloatingMicButton(voice: voice, targetText: $inputText) { text in
                    // Auto-send if desired; for now, just populate input.
                    inputText = text
                }
                .padding(.trailing, 16)
                .padding(.bottom, 90)
            }
            .toolbar { toolbar }
            .navigationTitle("Jarvis")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(.orangeBrand)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button { selectedTab = .chat } label: { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
            Spacer()
            Button { selectedTab = .calendar } label: { Label("Calendar", systemImage: "calendar") }
            Spacer()
            Button { selectedTab = .mood } label: { Label("Mood", systemImage: "face.smiling") }
            Spacer()
            Button { selectedTab = .sounds } label: { Label("Sounds", systemImage: "waveform") }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .chat:
            ChatCompanionView(viewModel: viewModel, inputText: $inputText)
        case .calendar:
            CalendarCardsView()
        case .mood:
            MoodTrackerView()
        case .sounds:
            SoundscapesView()
        }
    }
}

// MARK: - Chat Companion (Livie-style)
struct ChatCompanionView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Binding var inputText: String
    @AppStorage("accountName") private var accountName: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        bubble(for: msg)
                    }
                    if let suggestion = proactiveSuggestion() {
                        SuggestionCard(text: suggestion) { accept in
                            if accept { inputText = suggestion }
                        }
                    }
                }
                .padding()
            }
            inputBar
        }
        .onAppear {
            if viewModel.messages.isEmpty {
                let name = accountName.isEmpty ? "friend" : accountName
                viewModel.appendSystem("Hey \(name)! How are you feeling today? 😊")
            }
        }
    }

    @ViewBuilder
    private func bubble(for message: ChatMessage) -> some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                Text(message.text)
                    .padding(12)
                    .background(Color.orangeBrand.opacity(0.1))
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(message.text)
                    .padding(12)
                    .background(Color.orangeBrand)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Type a message…", text: $inputText)
                .textFieldStyle(.roundedBorder)
            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.orangeBrand))
            }
        }
        .padding()
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.send(text)
        inputText = ""
    }

    private func proactiveSuggestion() -> String? {
        // Very simple heuristic: ask about goals or reminders
        let lower = viewModel.messages.last?.text.lowercased() ?? ""
        if lower.contains("doctor") && !lower.contains("remind") {
            return "I noticed you have a doctor's appointment tomorrow. Want me to remind you to grab roses for Bella? 💐"
        }
        if lower.contains("birthday") {
            return "It's your mom's birthday next week—want me to set a reminder?"
        }
        return nil
    }
}

struct SuggestionCard: View {
    let text: String
    var onDecision: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text)
            HStack {
                Button("Yes") { onDecision(true) }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                Button("No") { onDecision(false) }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Mood Tracker
struct MoodTrackerView: View {
    @State private var mood: Double = 6
    @State private var history: [Date: Int] = [:]

    var body: some View {
        VStack(spacing: 16) {
            Text("How are you feeling today?")
                .font(.headline)
            HStack {
                Text("😞")
                Slider(value: $mood, in: 1...10, step: 1)
                Text("🤩")
            }
            Button("Save Mood") {
                history[Date()] = Int(mood)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orangeBrand)
            List(history.sorted(by: { $0.key > $1.key }), id: \.key) { date, value in
                HStack {
                    Text(date, style: .date)
                    Spacer()
                    Text("\(value)")
                }
            }
        }
        .padding()
    }
}

// MARK: - Calendar Cards (stub)
struct CalendarCardsView: View {
    var body: some View {
        List {
            Section("Today") {
                Label("Standup 9:30am", systemImage: "calendar")
                Label("Doctor 2:00pm", systemImage: "cross.case.fill")
            }
            Section("Tomorrow") {
                Label("Lunch with Jimmy", systemImage: "fork.knife")
            }
            Section("This Week") {
                Label("Mom's Birthday", systemImage: "gift.fill")
            }
        }
    }
}

// MARK: - Soundscapes (Focus Mode)
import AVFoundation

struct SoundscapesView: View {
    @State private var player: AVAudioPlayer?

    var body: some View {
        List {
            Button("Rain") { play("rain") }
            Button("Ocean") { play("ocean") }
            Button("Fireplace") { play("fireplace") }
            Button("White Noise") { play("whitenoise") }
        }
    }

    private func play(_ name: String) {
        // In a real app, bundle or stream these assets.
        // Here we just stop any current playback.
        player?.stop()
    }
}
