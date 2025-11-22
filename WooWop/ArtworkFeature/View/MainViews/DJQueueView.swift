//
//  DJQueueView.swift
//  WooWop
//
//  Created by Theron Jones on 10/6/25.
//

import SwiftUI

/// Main interface for DJs to manage incoming song requests and session controls.
/// 
/// This view provides comprehensive DJ functionality including session management,
/// real-time display of incoming song requests, and controls for starting/stopping
/// DJ mode. It shows connection status and allows DJs to mark requests as completed.
struct DJQueueView: View {
    /// Manager handling multipeer connectivity and song request data
    @ObservedObject var multipeerManager: MultipeerManager
    @State private var isSyncing: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // After Hours cyberpunk background
                ZStack {
                    // Midnight gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.059, green: 0.047, blue: 0.161), // Deep midnight
                            Color(red: 0.102, green: 0.102, blue: 0.180)  // Dark purple-black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(.all)
                    
                    // Club light effects
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.0, blue: 0.6).opacity(0.1), // Electric pink
                            Color(red: 0.059, green: 0.047, blue: 0.161).opacity(0.3),
                            Color(red: 0.102, green: 0.102, blue: 0.180)
                        ]),
                        center: .topTrailing,
                        startRadius: 50,
                        endRadius: 400
                    )
                    .ignoresSafeArea(.all)
                    .blendMode(.overlay)
                }
                
                VStack(spacing: 16) {
                    // DJ Status Header with cyberpunk styling
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(multipeerManager.isDJ ? Color(red: 0.0, green: 0.941, blue: 1.0) : Color.gray) // Electric blue
                                .frame(width: 12, height: 12)
                                .shadow(
                                    color: multipeerManager.isDJ ? Color(red: 0.0, green: 0.941, blue: 1.0) : Color.clear,
                                    radius: 4
                                )
                            
                            Text(multipeerManager.isDJ ? "DJ Mode Active" : "DJ Mode Inactive")
                                .font(.headline.weight(.medium))
                                .textCase(.uppercase)
                                .foregroundColor(multipeerManager.isDJ ? Color(red: 0.0, green: 0.941, blue: 1.0) : Color.gray)
                        }
                        
                        Text("\(multipeerManager.connectedPeers.count) connected devices")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.086, green: 0.129, blue: 0.243).opacity(0.6)) // Surface card
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                                                Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(
                        color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    
                    // For listeners, show the currently-discovered DJ's name if available
                    if !multipeerManager.isDJ {
                        HStack(spacing: 8) {
                            if let dj = multipeerManager.currentDJName, !dj.isEmpty {
                                Text("DJ \(dj)")
                                    .font(.subheadline)
                                    .bold()
                            } else if multipeerManager.djAvailable {
                                Text("DJ: (unknown)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No DJ connected")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 4)
                    }
                    
                    // Control Buttons: only visible to the DJ. Listeners should not see Start/Stop controls.
                    if multipeerManager.isDJ {
                        HStack(spacing: 16) {
                            // Start DJ Mode with Neon Glow Style
                            Button {
                                multipeerManager.startHosting()
                            } label: {
                                HStack {
                                    Image(systemName: "broadcast")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.white)
                                    Text("Start DJ Mode")
                                        .font(.system(.title2, design: .default, weight: .bold))
                                        .textCase(.uppercase)
                                }
                                .foregroundColor(Color.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 1.0, green: 0.0, blue: 0.6)) // Electric pink
                                )
                                .shadow(
                                    color: Color(red: 1.0, green: 0.0, blue: 0.6).opacity(0.6),
                                    radius: 10,
                                    x: 0,
                                    y: 5
                                )
                            }
                            .disabled(multipeerManager.isDJ || (multipeerManager.isConnected && !multipeerManager.isDJ))
                            
                            // Stop button with Ghost Style
                            Button {
                                multipeerManager.stopSession()
                            } label: {
                                HStack {
                                    Image(systemName: "stop.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(red: 0.914, green: 0.271, blue: 0.376)) // Soft red
                                    Text("Stop")
                                        .font(.system(.body, design: .default, weight: .semibold))
                                        .textCase(.uppercase)
                                }
                                .foregroundColor(Color(red: 0.914, green: 0.271, blue: 0.376))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .strokeBorder(Color(red: 0.914, green: 0.271, blue: 0.376), lineWidth: 2)
                                )
                            }
                            .padding()
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(!multipeerManager.isDJ && !multipeerManager.isConnected)
                    } else {
                        // For listeners, show a subtle informational label while keeping the queue visible
                        HStack(spacing: 8) {
                            Text("Viewing DJ queue")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                            
                            // Manual refresh in case automatic retries fail
                            Button {
                                isSyncing = true
                                multipeerManager.requestQueue()
                                // quick retry after a short delay
                                Task {
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    multipeerManager.requestQueue()
                                    try? await Task.sleep(nanoseconds: 500_000_000)
                                    isSyncing = false
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                                    .padding(6)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.4))
                                    )
                                    .shadow(
                                        color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                                        radius: 4
                                    )
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    
                    // Song Requests List  
                    List {
                        ForEach(multipeerManager.receivedRequests.sorted(by: { 
                            // Primary sort: highest upvotes first (use upvoters.count as source of truth)
                            if $0.upvoters.count != $1.upvoters.count {
                                return $0.upvoters.count > $1.upvoters.count
                            }
                            // Secondary sort: oldest requests first (tiebreaker)
                            return $0.timestamp < $1.timestamp
                        })) { request in
                            let localName = multipeerManager.localDisplayName
                            let canUpvote = (request.requesterName != localName) && !request.upvoters.contains(localName)
                            
                            // determine local permissions
                            let canRemove = multipeerManager.isDJ || (request.requesterName == localName)
                            SongRequestRow(
                                request: request,
                                onRemove: {
                                    // removal will be handled after confirmation inside the row via this callback
                                    if multipeerManager.isDJ {
                                        // Authoritative removal: DJ removes locally and broadcasts updated queue
                                        multipeerManager.removeSongRequest(request)
                                        multipeerManager.broadcastQueue()
                                    } else {
                                        // Ask the DJ to remove this item
                                        multipeerManager.sendRemoveRequest(request.id)
                                    }
                                },
                                onUpvote: {
                                    // Block self-votes and duplicate votes locally before sending
                                    let localName = multipeerManager.localDisplayName
                                    // If the requester is the local user, disallow upvoting own request
                                    guard request.requesterName != localName else {
                                        print("Local user cannot upvote their own request")
                                        return
                                    }
                                    // If we've already upvoted, don't send again
                                    if request.upvoters.contains(localName) {
                                        print("Local user has already upvoted this request")
                                        return
                                    }
                                    
                                    // Optimistically record the vote locally
                                    if let idx = multipeerManager.receivedRequests.firstIndex(where: { $0.id == request.id }) {
                                        multipeerManager.receivedRequests[idx].upvoters.append(localName)
                                        multipeerManager.receivedRequests[idx].upvotes = multipeerManager.receivedRequests[idx].upvoters.count
                                    }
                                    
                                    // Send the upvote to peers (DJ will reconcile and rebroadcast authoritative queue)
                                    multipeerManager.sendUpvote(request.id)
                                },
                                canUpvote: canUpvote,
                                canRemove: canRemove
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                    
                    if multipeerManager.receivedRequests.isEmpty && multipeerManager.isDJ {
                        Spacer()
                        Text("No song requests yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .navigationTitle("DJ Queue")
            }
            .onAppear {
                // If we're a listener, ask the connected DJ(s) for the current queue when the user opens the view
                if !multipeerManager.isDJ {
                    isSyncing = true
                    // Ensure we're browsing/attempting to connect if not already
                    if !multipeerManager.hasJoinedSession && !multipeerManager.isConnected {
                        multipeerManager.joinSession()
                    }
                    
                    Task {
                        // Wait up to ~4 seconds for a connection to appear
                        var waited = 0
                        while multipeerManager.connectedPeers.isEmpty && waited < 20 {
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            waited += 1
                        }
                        
                        // Request queue once we have at least one connected peer, or immediately if timeout
                        multipeerManager.requestQueue()
                        
                        // If still empty, try a couple more times spaced out
                        if multipeerManager.receivedRequests.isEmpty {
                            for _ in 0..<3 {
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                multipeerManager.requestQueue()
                                if !multipeerManager.receivedRequests.isEmpty { break }
                            }
                        }
                        
                        // Allow any incoming update to settle
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        isSyncing = false
                    }
                }
            }
        }
    }
}

/// Individual row component displaying a single song request.
/// 
/// This view presents the details of a song request including title, artist,
/// requester name, and timestamp. It provides a completion button for DJs
/// to mark requests as fulfilled.
struct SongRequestRow: View {
    /// The song request data to display
    let request: SongRequest
    
    /// Callback executed when the DJ marks this request as completed
    let onRemove: () -> Void
    
    /// Callback executed when a listener upvotes this request
    let onUpvote: () -> Void

    /// Whether the local user is allowed to upvote this request (for disabling the UI)
    let canUpvote: Bool
    /// Whether the local user is allowed to remove this request (DJ or original requester)
    let canRemove: Bool

    
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("by \(request.artist)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("Requested by \(request.requesterName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(request.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()

            // Upvote count + button (listeners can upvote)
            HStack(spacing: 8) {
                Text("\(request.upvotes)")
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Button {
                    onUpvote()
                } label: {
                    Image(systemName: "hand.thumbsup")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 0.0, green: 0.941, blue: 1.0)) // Electric blue
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                        )
                        .shadow(
                            color: Color(red: 0.0, green: 0.941, blue: 1.0).opacity(0.3),
                            radius: 4
                        )
                }
                .buttonStyle(.borderless)
                .disabled(!canUpvote)
            }
        }
        .padding(.vertical, 4)
        // Swipe to remove (requires explicit confirmation). Only show when permitted.
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if canRemove {
                Button(role: .destructive) {
                    // Immediately perform removal when swiped (no confirmation)
                    onRemove()
                } label: {
                    Label("Remove", systemImage: "trash.fill")
                }
                .tint(.red)
            }
        }
    }
}

#Preview {
    DJQueueView(multipeerManager: MultipeerManager())
}
