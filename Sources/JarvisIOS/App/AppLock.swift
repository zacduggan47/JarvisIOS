import SwiftUI
import LocalAuthentication

@MainActor
final class AppLock: ObservableObject {
    @Published var isLocked: Bool = true

    func lock() { isLocked = true }

    func unlockWithBiometrics() {
        Task { [weak self] in
            let context = LAContext()
            var error: NSError?
            let reason = "Unlock Jarvis"

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) ||
                context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                do {
                    try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                    self?.isLocked = false
                } catch {
                    // Stay locked on failure
                }
            }
        }
    }
}

struct LockView: View {
    var onUnlock: () -> Void

    var body: some View {
        ZStack {
            VisualEffectBlur()
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "app.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orangeBrand)
                Text("Jarvis Locked")
                    .font(.headline)
                Button {
                    onUnlock()
                } label: {
                    Label("Unlock with Face ID", systemImage: "faceid")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orangeBrand)
            }
            .padding()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Lock screen")
    }
}

struct PrivacyShieldView: View {
    var body: some View {
        VisualEffectBlur()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// Simple UIKit blur wrapper for privacy/lock overlays
struct VisualEffectBlur: UIViewRepresentable {
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}
