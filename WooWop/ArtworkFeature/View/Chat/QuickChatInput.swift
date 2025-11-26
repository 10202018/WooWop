import SwiftUI

/// Quick chat input component for sending text messages and emoji reactions
/// Designed as a compact overlay that appears over the main content
struct QuickChatInput: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @Binding var isPresented: Bool
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // Quick emoji options
    private let quickEmojis = ["❤️", "🔥", "👏", "😂", "🎵", "🎉", "💃", "🕺", "🎤", "🎧"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Quick emoji reactions row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickEmojis, id: \.self) { emoji in
                        Button {
                            sendEmoji(emoji)
                        } label: {
                            Text(emoji)
                                .font(.title2)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Text input section
            HStack(spacing: 12) {
                // Text field
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }
                
                // Send button
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(messageText.isEmpty ? Color.gray : Color.blue)
                        )
                }
                .disabled(messageText.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 10)
        )
        .onAppear {
            // Auto-focus text field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let chatMessage = ChatMessage(text: trimmed, senderName: multipeerManager.localDisplayName)
        multipeerManager.sendChatMessage(chatMessage)
        messageText = ""
        
        // Close input after sending
        withAnimation {
            isPresented = false
        }
    }
    
    private func sendEmoji(_ emoji: String) {
        multipeerManager.sendEmojiReaction(emoji)
        
        // Close input after sending emoji
        withAnimation {
            isPresented = false
        }
    }
}

#Preview {
    QuickChatInput(
        multipeerManager: MultipeerManager(),
        isPresented: Binding.constant(true)
    )
    .background(Color.black.opacity(0.3))
}