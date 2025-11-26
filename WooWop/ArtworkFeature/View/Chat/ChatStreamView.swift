import SwiftUI

struct ChatStreamView: View {
    @ObservedObject var multipeerManager: MultipeerManager
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        // Add spacer at the top to push messages to bottom initially
                        Spacer()
                            .frame(height: max(0, geometry.size.height - chatContentHeight))
                            .id("spacer")
                        
                        ForEach(multipeerManager.chatMessages) { message in
                            ChatMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                }
                .scrollDisabled(false)
                .onAppear {
                    if let lastMessage = multipeerManager.chatMessages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
                        }
                    }
                }
                .onChange(of: multipeerManager.chatMessages) { messages in
                    if let lastMessage = messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: UnitPoint.bottom)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    
    private var chatContentHeight: CGFloat {
        // Estimate height based on message count
        return CGFloat(multipeerManager.chatMessages.count * 50) // Rough estimate
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.8
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                // Always show sender name for all messages
                Text(message.senderName)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .fontWeight(.medium)
                
                // Message content
                HStack(spacing: 4) {
                    if message.isEmoji {
                        // Large emoji display
                        Text(message.displayText)
                            .font(.title2)
                    } else {
                        // Regular text message
                        Text(message.displayText)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                    }
                    
                    if let gifURL = message.gifURL {
                        // TODO: Add GIF support when ready
                        Image(systemName: "photo")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(message.isEmoji ? Color.clear : Color.black.opacity(0.6))
                .blur(radius: 0.5)
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                opacity = 1.0
                scale = 1.0
            }
            
            // Auto-fade after delay (except for emojis which stay longer)
            let fadeDelay: Double = message.isEmoji ? 8.0 : 5.0
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDelay) {
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 0.3
                }
            }
        }
    }
}

// MARK: - TikTok-Style Chat Overlay
struct TikTokChatOverlay: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @State private var showInput = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Chat stream area
                        ChatStreamView(multipeerManager: multipeerManager)
                            .frame(width: min(260, geometry.size.width * 0.7))
                            .frame(maxHeight: min(400, geometry.size.height * 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        
                        // Quick input area
                        HStack(spacing: 12) {
                            // Quick emoji reactions
                            HStack(spacing: 8) {
                                ForEach(["❤️", "🔥", "👏", "😂"], id: \.self) { emoji in
                                    Button {
                                        multipeerManager.sendEmojiReaction(emoji)
                                    } label: {
                                        Text(emoji)
                                            .font(.title2)
                                            .padding(8)
                                            .background(Color.black.opacity(0.4))
                                            .clipShape(Circle())
                                    }
                                }
                            }
                            
                            // Chat toggle button
                            Button {
                                showInput.toggle()
                            } label: {
                                Image(systemName: "message")
                                    .foregroundColor(.white)
                                    .font(.title2)
                                    .padding(10)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)
                    }
                    .background(
                        // Subtle background to ensure visibility over any background image
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black.opacity(0.1))
                            .blur(radius: 8)
                            .padding(-8)
                    )
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .sheet(isPresented: $showInput) {
                QuickChatInput(multipeerManager: multipeerManager, isPresented: $showInput)
                    .frame(height: 120)
            }
        }
    }
}

#if DEBUG
struct ChatStreamView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.ignoresSafeArea()
            
            TikTokChatOverlay(multipeerManager: MultipeerManager())
        }
    }
}
#endif
