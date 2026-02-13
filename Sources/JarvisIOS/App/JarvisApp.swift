import SwiftUI
import Combine
import UIKit

@main
struct JarvisApp: App {
    @AppStorage("appearance") private var appearance: String = "system"

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(.orangeBrand)
                .preferredColorScheme(colorScheme(from: appearance))
        }
    }

    private func colorScheme(from value: String) -> ColorScheme? {
        switch value {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

private struct RootView: View {
    @State private var showOnboarding = false
    @State private var showSkills = false
    @State private var showChat = false
    @StateObject private var chatViewModel = ChatViewModel(gatewayClient: GatewayClient())

    var body: some View {
        WelcomeView()
            .fullScreenCover(isPresented: $showOnboarding, onDismiss: { showSkills = true }) {
                OnboardingView(isComplete: $showOnboarding)
            }
            .fullScreenCover(isPresented: $showSkills, onDismiss: { showChat = true }) {
                SkillsView()
            }
            .fullScreenCover(isPresented: $showChat) {
                ChatView(viewModel: chatViewModel)
            }
            .environment(\.showOnboardingBinding, $showOnboarding)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @Environment(\.showOnboardingBinding) private var showOnboarding

    var body: some View {
        ZStack {
            Color.orangeBrand.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("🦞").font(.system(size: 80))
                    Text("J A R V I S")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.orangeBrand)
                }
                
                Spacer()
                
                Button(action: { showOnboarding?.wrappedValue = true }) {
                    Text("🚀 RUN CLAW")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.orangeBrand)
                        .cornerRadius(16)
                        .shadow(color: .orangeBrand.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                
                Text("Made with ❤️ for you")
                    .font(.caption).foregroundColor(.gray)
                
                Spacer().frame(height: 40)
            }
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep = 0
    @State private var answers: [String] = Array(repeating: "", count: 14)
    @State private var showWhy = false
    @State private var isSubmitting = false
    @State private var showConfetti = false
    @State private var errorMessage: String?
    @AppStorage("subscriptionTier") private var subscriptionTier: String = "Free"
    @AppStorage("userId") private var userId: String = ""
    @AppStorage("accountName") private var accountName: String = ""

    let memoryQuestions = [
        "What should I call you?",
        "What do you do for work?",
        "What do you want to achieve?",
        "What do you struggle with?",
        "How do you want me to message you?",
        "Any do's or don'ts?",
        "Anything else I should know?"
    ]
    
    let soulQuestions = [
        "How should I sound? (Direct/Friendly/Professional/Casual)",
        "What's your humor? (Dark/Dry/Light/None)",
        "My energy: (Calm/Medium/Enthusiastic)",
        "Topics to avoid?",
        "How should I talk? (Short/Detailed/Bullet points)",
        "What motivates you?",
        "What makes you happy?"
    ]
    
    let whyMemory = [
        "We’ll use your name to personalize chat and files.",
        "Your role helps tailor suggestions and skills.",
        "Goals guide priorities and morning briefs.",
        "Struggles help the AI support you compassionately.",
        "Messaging style lets Jarvis match your pace.",
        "Dos/don’ts set boundaries and preferences.",
        "Anything else helps us start on the right foot."
    ]

    let whySoul = [
        "Tone shapes how Jarvis speaks to you.",
        "Humor settings keep jokes welcome—or not.",
        "Energy level matches your preferred vibe.",
        "Topics to avoid protect your boundaries.",
        "Response style matches your information needs.",
        "Motivation style helps Jarvis encourage you.",
        "Happiness cues help Jarvis celebrate wins."
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 8) {
                ForEach(0..<14, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.orangeBrand : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            
            Text(progressLabel)
                .font(.caption.bold())
                .foregroundColor(.orangeBrand)
                .padding(.top, 8)
            
            Spacer()
            
            // Question
            let question = currentStep < 7 
                ? memoryQuestions[currentStep]
                : soulQuestions[currentStep - 7]
            
            HStack(spacing: 8) {
                Text(question)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Button {
                    showWhy = true
                } label: {
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.orangeBrand)
                }
            }
            .padding(.horizontal, 24)
            .id("q\(currentStep)")
            .transition(.opacity.combined(with: .scale))
            
            Spacer()
            
            // Answer Input
            TextField("Your answer...", text: $answers[currentStep])
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
                .id("a\(currentStep)")
                .transition(.opacity.combined(with: .scale))
            
            Spacer()
            
            // Buttons
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("← Back") {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { currentStep -= 1 }
                    }
                    .foregroundColor(.gray)
                }

                Button("Skip") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { currentStep = min(currentStep + 1, 13) }
                }
                .foregroundColor(.secondary)

                Button(currentStep < 13 ? "Next →" : "Done!") {
                    if currentStep < 13 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { currentStep += 1 }
                    } else {
                        Task { await submitOnboarding() }
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(.orangeBrand)
            }
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showWhy) {
            WhySheetView(message: currentWhyText)
        }
        .overlay {
            ZStack {
                if isSubmitting {
                    ProgressView("Setting up your Jarvis...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                if let error = errorMessage {
                    VStack {
                        Text(error)
                            .font(.footnote)
                            .padding(8)
                            .background(Color.red.opacity(0.15))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                            .padding(.top, 12)
                        Spacer()
                    }
                }
            }
        }
    }

    private var currentWhyText: String {
        currentStep < 7 ? whyMemory[currentStep] : whySoul[currentStep - 7]
    }
    
    private var progressLabel: String {
        if currentStep < 7 {
            return "Memory \(currentStep + 1)/7"
        } else {
            return "Soul \((currentStep - 7) + 1)/7"
        }
    }

    private func submitOnboarding() async {
        isSubmitting = true
        errorMessage = nil
        let memory = Array(answers.prefix(7))
        let soul = Array(answers.suffix(7))
        let skills = UserDefaults.standard.array(forKey: "connectedSkills") as? [String] ?? []
        do {
            let id = try await GatewayClient().connectUser(
                memoryAnswers: memory,
                soulAnswers: soul,
                subscriptionTier: subscriptionTier,
                connectedSkills: skills
            )
            userId = id
            if let name = memory.first, !name.isEmpty { accountName = name }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation { showConfetti = true }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showConfetti = false
            isSubmitting = false
            isComplete = false
        } catch {
            isSubmitting = false
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Skills View
struct SkillsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showOAuth = false
    @State private var showConfigure = false
    @State private var pendingSkill: SkillItem?
    @State private var connected: Set<String> = []
    @State private var showMore = false

    private let connectedSkillsKey = "connectedSkills"

    struct SkillItem: Identifiable, Hashable {
        let id: String
        let icon: String
        let name: String
        let description: String
    }

    private let skills: [SkillItem] = [
        SkillItem(id: "gmail", icon: "envelope.fill", name: "Gmail", description: "Sync emails, calendar, contacts"),
        SkillItem(id: "calendar", icon: "calendar", name: "Calendar", description: "Manage your events"),
        SkillItem(id: "whatsapp", icon: "message.circle.fill", name: "WhatsApp", description: "Send messages, check history"),
        SkillItem(id: "things", icon: "checkmark.square", name: "Things", description: "Tasks from Things 3"),
        SkillItem(id: "weather", icon: "cloud.sun.fill", name: "Weather", description: "Local forecasts"),
        SkillItem(id: "sonos", icon: "speaker.wave.2.fill", name: "Sonos", description: "Control music"),
        SkillItem(id: "hue", icon: "lightbulb.fill", name: "Hue", description: "Smart lights"),
        SkillItem(id: "gym", icon: "dumbbell.fill", name: "Gym", description: "Workout tracking")
    ]

    private var coreSkills: [SkillItem] { skills.filter { ["gmail", "calendar"].contains($0.id) } }
    private var extraSkills: [SkillItem] { skills.filter { !["gmail", "calendar"].contains($0.id) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(coreSkills) { skill in
                        skillCard(skill)
                    }

                    if showMore {
                        ForEach(extraSkills) { skill in
                            skillCard(skill)
                        }
                    } else {
                        Button {
                            withAnimation { showMore = true }
                        } label: {
                            Label("Show more skills", systemImage: "chevron.down")
                        }
                        .buttonStyle(.bordered)
                        .tint(.orangeBrand)
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.orangeBrand.opacity(0.06).ignoresSafeArea())
            .navigationTitle("Connect Skills")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip for now") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { dismiss() }) {
                        Text("Continue to Chat")
                            .fontWeight(.bold)
                    }
                }
            }
            .onAppear { loadConnected() }
            .refreshable { await refreshStatuses() }
            .sheet(isPresented: $showOAuth) {
                OAuthStubView(skillName: pendingSkill?.name ?? "Skill") {
                    if let id = pendingSkill?.id {
                        connected.insert(id)
                        saveConnected()
                    }
                    showOAuth = false
                    pendingSkill = nil
                }
            }
            .sheet(isPresented: $showConfigure) {
                ConfigureStubView(skillName: pendingSkill?.name ?? "Skill") {
                    showConfigure = false
                    pendingSkill = nil
                }
            }
        }
    }

    @ViewBuilder
    private func skillCard(_ skill: SkillItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: skill.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.orangeBrand)
                    .frame(width: 44, height: 44)
                    .background(Color.orangeBrand.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(skill.name)
                            .font(.headline)
                        if connected.contains(skill.id) {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .labelStyle(.titleAndIcon)
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text("Not Connected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Text(skill.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if connected.contains(skill.id) {
                    Button("Configure") {
                        pendingSkill = skill
                        showConfigure = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.orangeBrand)
                } else {
                    Button("Connect") {
                        pendingSkill = skill
                        showOAuth = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orangeBrand)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orangeBrand.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private func loadConnected() {
        let arr = UserDefaults.standard.array(forKey: connectedSkillsKey) as? [String] ?? []
        connected = Set(arr)
    }

    private func saveConnected() {
        UserDefaults.standard.set(Array(connected), forKey: connectedSkillsKey)
    }

    private func refreshStatuses() async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        await MainActor.run { loadConnected() }
    }
}

struct OAuthStubView: View {
    let skillName: String
    let onComplete: () -> Void

    @State private var isConnecting = true

    var body: some View {
        VStack(spacing: 16) {
            Text("Connecting \(skillName)…")
                .font(.title3.bold())
            ProgressView()
            Text("Simulating one-tap OAuth…")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                isConnecting = false
                onComplete()
            }
        }
    }
}

struct ConfigureStubView: View {
    let skillName: String
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Text("Configure \(skillName)")
                .font(.title2.bold())
            Text("This is a stub for configuration.\nIn production, settings for \(skillName) will appear here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            Button("Done") { onDone() }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orangeBrand)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct WhySheetView: View {
    @Environment(\.dismiss) private var dismiss
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Text("Why we ask")
                .font(.title2.bold())
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Got it") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.orangeBrand)
        }
        .padding()
    }
}

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: UIScreen.main.bounds.width/2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: UIScreen.main.bounds.width, height: 1)

        let colors: [UIColor] = [.systemOrange, .systemPink, .systemYellow, .systemGreen, .systemBlue]
        var cells: [CAEmitterCell] = []
        for _ in 0..<12 {
            let cell = CAEmitterCell()
            cell.birthRate = 6
            cell.lifetime = 6
            cell.velocity = 180
            cell.velocityRange = 60
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spinRange = 3.5
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.color = colors.randomElement()?.cgColor
            cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal).cgImage
            cells.append(cell)
        }
        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitter.birthRate = 0
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

private struct ShowOnboardingKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}
extension EnvironmentValues {
    var showOnboardingBinding: Binding<Bool>? {
        get { self[ShowOnboardingKey.self] }
        set { self[ShowOnboardingKey.self] = newValue }
    }
}

