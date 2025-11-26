//
//  ChatMessage.swift
//  WooWop
//
//  Created on 11/26/25.
//

import Foundation

/// Represents a chat message in the live social feed.
/// 
/// Supports text messages, emoji reactions, and optional GIF URLs for rich messaging
/// in the TikTok-style chat experience. Messages are transmitted via MultipeerConnectivity
/// for real-time P2P communication between DJs and listeners.
struct ChatMessage: Codable, Identifiable, Equatable {
    /// Unique identifier for the message
    let id = UUID()
    
    /// The text content of the message (nil for GIF-only messages)
    let text: String?
    
    /// Optional URL for GIF content
    let gifURL: URL?
    
    /// Display name of the user who sent the message
    let senderName: String
    
    /// When the message was created
    let timestamp: Date
    
    /// True if this is an emoji reaction (single emoji character)
    let isEmoji: Bool
    
    /// Creates a text-based chat message
    init(text: String, senderName: String, isEmoji: Bool = false) {
        self.text = text
        self.gifURL = nil
        self.senderName = senderName
        self.timestamp = Date()
        self.isEmoji = isEmoji
    }
    
    /// Creates a GIF-based chat message
    init(gifURL: URL, senderName: String) {
        self.text = nil
        self.gifURL = gifURL
        self.senderName = senderName
        self.timestamp = Date()
        self.isEmoji = false
    }
    
    /// Creates a combined text + GIF message
    init(text: String?, gifURL: URL?, senderName: String, isEmoji: Bool = false) {
        self.text = text
        self.gifURL = gifURL
        self.senderName = senderName
        self.timestamp = Date()
        self.isEmoji = isEmoji
    }
    
    // MARK: - Helper Properties
    
    /// Returns true if this message has any content (text or GIF)
    var hasContent: Bool {
        return (text != nil && !text!.isEmpty) || gifURL != nil
    }
    
    /// Returns a display-friendly version of the message content
    var displayText: String {
        if let text = text {
            return text
        } else if gifURL != nil {
            return "🎬 GIF"
        } else {
            return ""
        }
    }
    
    /// Returns true if this message was sent recently (within 10 seconds)
    var isRecent: Bool {
        Date().timeIntervalSince(timestamp) < 10.0
    }
}

// MARK: - Codable Implementation

extension ChatMessage {
    /// Custom coding keys to ensure UUID is properly encoded/decoded
    private enum CodingKeys: String, CodingKey {
        case id, text, gifURL, senderName, timestamp, isEmoji
    }
}