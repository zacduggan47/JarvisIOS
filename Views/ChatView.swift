import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Error Banner
            if let error = viewModel.errorMessage {
                Textfont(.caption)
(error)
                    .                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
            
            // Input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.sendMessage()
                    }
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                    }
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(viewModel.inputText.isEmpty ? Color.gray : Color.orange)
                .cornerRadius(10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.isFromUser ? Color.orange : Color.gray.opacity(0.2))
                .foregroundColor(message.isFromUser ? .white : .primary)
                .cornerRadius(16)
            
            if !message.isFromUser { Spacer() }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatViewModel())
}
