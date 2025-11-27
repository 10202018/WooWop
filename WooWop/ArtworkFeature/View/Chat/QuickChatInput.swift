import SwiftUI

/// Quick chat input component for sending text messages and emoji reactions
/// Designed as a compact overlay that appears over the main content
// MARK: - Floating Chat Input
struct FloatingChatInput: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @Binding var isPresented: Bool
    @State private var messageText = ""
    @State private var showEmojiPicker = false
    @State private var dragOffset = CGSize.zero
    @FocusState private var isTextFieldFocused: Bool
    
    // Emoji categories for picker
    private let emojiCategories = [
        "❤️🔥👏🏾😂🎵🎉💃🏾🕺🏾🎤🎧",
        "😀😃😄😁😊😍🥰😘😜🤪",
        "👍🏾👎🏾✋🏾🤞🏾✌🏾🤟🏾💪🏾🙏🏾🔥❤️",
        "🎵🎶🎤🎧🎼🎹🥳🎉🎊🎈"
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 4) {
                // Emoji picker (floats above input)
                if showEmojiPicker {
                    emojiPickerView
                        .frame(width: inputWidth)
                }
                
                // Main floating input bar
                mainInputBar
                    .frame(width: inputWidth)
            }
            .padding(.bottom, 17) // Move up 5 points from bottom
        }
        .ignoresSafeArea(.container, edges: .bottom) // Extend to bottom edge
        .onTapGesture {
            withAnimation(.spring(response: 0.4)) {
                if showEmojiPicker {
                    showEmojiPicker = false
                } else {
                    isPresented = false
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4)) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    // Calculate fixed width based on device screen size
    private var inputWidth: CGFloat {
        UIScreen.main.bounds.width - 32 // 16pt padding on each side
    }
    
    // MARK: - Subviews
    
    private var emojiPickerView: some View {
        VStack(spacing: 6) {
            ForEach(Array(emojiCategories.enumerated()), id: \.offset) { index, categoryEmojis in
                emojiCategoryRow(for: categoryEmojis)
            }
        }
        .padding(.vertical, 8)
        .background(emojiPickerBackground)
        .transition(.move(edge: .bottom).combined(with: .scale))
    }
    
    private func emojiCategoryRow(for categoryEmojis: String) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(categoryEmojis.enumerated()), id: \.offset) { _, emoji in
                    emojiButton(for: emoji)
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func emojiButton(for emoji: Character) -> some View {
        Button {
            messageText += String(emoji)
        } label: {
            Text(String(emoji))
                .font(.title3)
                .padding(4)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
        }
    }
    
    private var emojiPickerBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.black.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3), lineWidth: 1)
            )
    }
    
    private var mainInputBar: some View {
        HStack(spacing: 8) {
            emojiToggleButton
            textInputField
            sendButton
            closeButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .padding(.bottom, 8) // Add bottom padding to clear home indicator
        .background(inputBarBackground)
        .offset(dragOffset)
        .gesture(dragGesture)
    }
    
    private var emojiToggleButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showEmojiPicker.toggle()
                if showEmojiPicker {
                    isTextFieldFocused = false
                }
            }
        } label: {
            Image(systemName: showEmojiPicker ? "keyboard" : "face.smiling")
                .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0))
                .font(.system(size: 18, weight: .medium))
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.7))
                )
        }
    }
    
    private var textInputField: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $messageText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: max(36, min(120, textHeight))) // Dynamic height based on content
                .background(textFieldBackground)
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .scrollContentBackground(.hidden) // Hide default TextEditor background
                .font(.system(size: 16)) // Set consistent font size
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showEmojiPicker = false
                    }
                }
            
            // Placeholder text
            if messageText.isEmpty {
                Text("Message...")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.system(size: 16))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false) // Allow taps to pass through
            }
        }
    }
    
    // Calculate dynamic height based on text content
    private var textHeight: CGFloat {
        if messageText.isEmpty {
            return 36 // Single line height when empty
        }
        
        let textWidth = inputWidth - 32 - 80 // Account for padding and buttons
        let font = UIFont.systemFont(ofSize: 16)
        let boundingRect = messageText.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        
        return max(36, min(120, boundingRect.height + 20)) // Add padding, constrain between 36-120
    }
    
    private var textFieldBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var sendButton: some View {
        Button {
            sendMessage()
        } label: {
            Image(systemName: "paperplane.fill")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .padding(10)
                .background(
                    Circle()
                        .fill(messageText.isEmpty ? Color.gray.opacity(0.5) : Color(red: 0.0, green: 0.941, blue: 1.0))
                )
        }
        .disabled(messageText.isEmpty)
    }
    
    private var closeButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                isPresented = false
            }
        } label: {
            Image(systemName: "xmark")
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 14, weight: .medium))
                .padding(10)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.7))
                )
        }
    }
    
    private var inputBarBackground: some View {
        RoundedRectangle(cornerRadius: 25)
            .fill(Color.black.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.4), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 15)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                withAnimation(.spring()) {
                    // Snap back to position or dismiss if dragged down
                    if value.translation.height > 100 {
                        isPresented = false
                    } else {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let chatMessage = ChatMessage(text: trimmed, senderName: multipeerManager.userName)
        multipeerManager.sendChatMessage(chatMessage)
        messageText = ""
        
        withAnimation(.spring(response: 0.4)) {
            isPresented = false
        }
    }
}

// MARK: - Legacy Quick Chat Input (keeping for compatibility)
struct QuickChatInput: View {
    @ObservedObject var multipeerManager: MultipeerManager
    @Binding var isPresented: Bool
    @State private var messageText = ""
    @State private var showEmojiPicker = false
    @FocusState private var isTextFieldFocused: Bool
    
    // Emoji categories for picker
    private let emojiCategories = [
        "❤️🔥👏🏾😂🎵🎉💃🏾🕺🏾🎤🎧",
        "😀😃😄😁😊😍🥰😘😜🤪",
        "👍🏾👎🏾✋🏾🤞🏾✌🏾🤟🏾���🏾🔥❤️",
        "🎵🎶🎤🎧🎼🎹🥳🎉🎊🎈"
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 4)
            
            // Emoji picker (show when toggled)
            if showEmojiPicker {
                VStack(spacing: 8) {
                    ForEach(Array(emojiCategories.enumerated()), id: \.offset) { index, categoryEmojis in
                        HStack(spacing: 6) {
                            ForEach(Array(categoryEmojis.enumerated()), id: \.offset) { _, emoji in
                                Button {
                                    messageText += String(emoji)
                                } label: {
                                    Text(String(emoji))
                                        .font(.title3)
                                        .padding(6)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.1))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Text input section
            HStack(spacing: 12) {
                // Emoji picker toggle button
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showEmojiPicker.toggle()
                        if showEmojiPicker {
                            isTextFieldFocused = false
                        }
                    }
                } label: {
                    Image(systemName: showEmojiPicker ? "keyboard" : "face.smiling")
                        .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0))
                        .font(.title2)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                
                // Text field with app-consistent styling
                TextField("Type a message...", text: $messageText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.white)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showEmojiPicker = false
                        }
                    }
                
                // Send button with app styling
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .padding(12)
                        .background(
                            Circle()
                                .fill(messageText.isEmpty ? Color.gray.opacity(0.5) : Color(red: 0.0, green: 0.941, blue: 1.0))
                        )
                }
                .disabled(messageText.isEmpty)
                .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 20)
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
        
        let chatMessage = ChatMessage(text: trimmed, senderName: multipeerManager.userName)
        multipeerManager.sendChatMessage(chatMessage)
        messageText = ""
        
        // Close input after sending
        withAnimation {
            isPresented = false
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        FloatingChatInput(
            multipeerManager: MultipeerManager(),
            isPresented: .constant(true)
        )
    }
}
