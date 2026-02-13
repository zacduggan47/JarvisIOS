import SwiftUI

@main
struct JarvisApp: App {
    var body: some Scene {
        WindowGroup {
            WelcomeView()
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1).ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text("🦞").font(.system(size: 80))
                    Text("J A R V I S")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button(action: { showOnboarding = true }) {
                    Text("🚀 RUN CLAW")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.orange)
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.4), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                
                Text("Made with ❤️ for you")
                    .font(.caption).foregroundColor(.gray)
                
                Spacer().frame(height: 40)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isComplete: $showOnboarding)
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep = 0
    @State private var answers: [String] = Array(repeating: "", count: 14)
    
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress
            HStack(spacing: 8) {
                ForEach(0..<14, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Question
            let question = currentStep < 7 
                ? memoryQuestions[currentStep]
                : soulQuestions[currentStep - 7]
            
            Text(question)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Answer Input
            TextField("Your answer...", text: $answers[currentStep])
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 20) {
                if currentStep > 0 {
                    Button("← Back") { withAnimation { currentStep -= 1 } }
                        .foregroundColor(.gray)
                }
                
                Button(currentStep < 13 ? "Next →" : "Done!") {
                    if currentStep < 13 {
                        withAnimation { currentStep += 1 }
                    } else {
                        isComplete = false
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(.orange)
            }
            .padding(.bottom, 40)
        }
    }
}
