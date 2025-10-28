//
//  DJQueueView.swift
//  WooWop
//
//  Created by AI Assistant on 10/6/25.
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
            VStack(spacing: 16) {
                // DJ Status Header
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(multipeerManager.isDJ ? .green : .gray)
                            .frame(width: 12, height: 12)
                        
                        Text(multipeerManager.isDJ ? "DJ Mode Active" : "DJ Mode Inactive")
                            .font(.headline)
                            .foregroundColor(multipeerManager.isDJ ? .green : .gray)
                    }
                    
                    Text("\(multipeerManager.connectedPeers.count) connected devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Control Buttons: only visible to the DJ. Listeners should not see Start/Stop controls.
                if multipeerManager.isDJ {
                    HStack(spacing: 16) {
                        Button {
                            multipeerManager.startHosting()
                        } label: {
                            HStack {
                                Image(systemName: "broadcast")
                                Text("Start DJ Mode")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        // Disable starting DJ mode if already DJ or if we're already connected to a peer
                        // (uses `isConnected` as a safe proxy for "another DJ present")
                        .disabled(multipeerManager.isDJ || (multipeerManager.isConnected && !multipeerManager.isDJ))

                        Button {
                            multipeerManager.stopSession()
                        } label: {
                            HStack {
                                Image(systemName: "stop.circle")
                                Text("Stop")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(!multipeerManager.isDJ && !multipeerManager.isConnected)
                    }
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
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                // Song Requests List
                List {
                    ForEach(multipeerManager.receivedRequests) { request in
                        SongRequestRow(request: request) {
                            multipeerManager.removeSongRequest(request)
                        }
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
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DJQueueView(multipeerManager: MultipeerManager())
}
