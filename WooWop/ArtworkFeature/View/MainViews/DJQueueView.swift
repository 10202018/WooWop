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
                
                // Control Buttons
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
                    .disabled(multipeerManager.isDJ)
                    
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
