import SwiftUI

struct FloatingMicButton: View {
    @ObservedObject var voice: VoiceInputManager
    @Binding var targetText: String
    @AppStorage("voiceEnabled") private var voiceEnabled: Bool = true
    @AppStorage("voiceLocale") private var voiceLocale: String = Locale.current.identifier
    @AppStorage("voiceAutoSend") private var voiceAutoSend: Bool = false

    var onSend: ((String) -> Void)?

    @State private var isPressed = false
    @State private var showRecordingUI = false

    var body: some View {
        Group {
            if voiceEnabled {
                ZStack {
                    Button(action: {}) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Circle().fill(Color.orangeBrand))
                    }
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.1).onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            showRecordingUI = true
                            voice.updateLocale(voiceLocale)
                            Task { await voice.startListening(autoPunctuation: true) }
                        }
                    }.onEnded { _ in
                        isPressed = false
                        voice.stop()
                    })

                    if showRecordingUI {
                        RecordingOverlay(state: voice.state, partial: voice.partialText)
                            .transition(.opacity)
                            .onChange(of: voice.state) { state in
                                switch state {
                                case .success(let text):
                                    targetText = text
                                    if voiceAutoSend { onSend?(text) }
                                    showRecordingUI = false
                                case .error:
                                    showRecordingUI = false
                                case .finishing:
                                    break
                                default:
                                    break
                                }
                            }
                    }
                }
                .padding()
                .accessibilityLabel("Hold to talk")
                .accessibilityHint("Long press to record, release to transcribe")
            }
        }
    }
}

private struct RecordingOverlay: View {
    let state: VoiceInputManager.State
    let partial: String

    var body: some View {
        VStack(spacing: 12) {
            PulseCircle()
                .frame(width: 80, height: 80)
            switch state {
            case .listening:
                Text("Listening…")
                    .font(.headline)
                    .foregroundColor(.red)
            case .success:
                Label("Captured", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .error:
                Label("Try again", systemImage: "xmark.octagon.fill")
                    .foregroundColor(.red)
            default:
                EmptyView()
            }
            if !partial.isEmpty {
                Text(partial)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(maxWidth: 320)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
    }
}

private struct PulseCircle: View {
    @State private var scale: CGFloat = 1
    @State private var opacity: Double = 1
    var body: some View {
        Circle()
            .stroke(Color.red, lineWidth: 4)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: false)) {
                    scale = 1.3
                    opacity = 0
                }
            }
    }
}
