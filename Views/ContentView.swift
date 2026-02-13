import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            WelcomeView()
        }
    }
}

struct WelcomeView: View {
    @State private var navigateToOnboarding = false
    
    var body: some View {
        ZStack {
            Color.orange.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo/Title
                VStack(spacing: 16) {
                    Text("🦞")
                        .font(.system(size: 80))
                    
                    Text("J A R V I S")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Big Button
                Button(action: {
                    navigateToOnboarding = true
                }) {
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
                
                // Footer
                Text("Made with ❤️ for you")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .navigationDestination(isPresented: $navigateToOnboarding) {
            OnboardingView()
        }
    }
}

struct OnboardingView: View {
    @State private var currentQuestion = 0
    @State private var answers: [String] = Array(repeating: "", count: 7)
    
    let questions = [
        "What should I call you?",
        "What do you do for work?",
        "What do you want to achieve?",
        "What do you struggle with?",
        "How do you want me to message you?",
        "Any do's or don'ts?",
        "Anything else I should know?"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Progress
            HStack {
                ForEach(0..<questions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentQuestion ? Color.orange : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Question
            Text(questions[currentQuestion])
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            // Answer Input
            TextField("Your answer...", text: $answers[currentQuestion])
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Buttons
            HStack(spacing: 20) {
                if currentQuestion > 0 {
                    Button("← Back") {
                        currentQuestion -= 1
                    }
                    .foregroundColor(.gray)
                }
                
                Button(currentQuestion < questions.count - ? "Next →" : "Done!") {
                    if currentQuestion < questions.count - 1 {
                        currentQuestion += 1
                    } else {
                        // Navigate to chat
                    }
                }
                .fontWeight(.bold)
                .foregroundColor(.orange)
            }
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    ContentView()
}
