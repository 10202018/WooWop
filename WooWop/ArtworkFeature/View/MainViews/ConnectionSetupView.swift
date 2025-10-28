//
//  ConnectionSetupView.swift
//  WooWop
//
//  Created by AI Assistant on 10/6/25.
//

import SwiftUI

/// Initial setup interface for choosing user role and configuring connectivity.
/// 
/// This view serves as the onboarding screen where users select their role
/// (DJ or Listener), set their display name, and initiate the appropriate
/// multipeer connectivity mode. It provides real-time feedback on connection status.
struct ConnectionSetupView: View {
    /// Manager handling multipeer connectivity setup and status
    @ObservedObject var multipeerManager: MultipeerManager
    
    /// User's display name for song requests and session identification
    @State private var userName: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "music.note.house")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("WooWop")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Request songs to the DJ or become the DJ yourself!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // User Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                    
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            multipeerManager.userName = userName
                        }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Mode Selection
                VStack(spacing: 16) {
                    Text("Choose your role:")
                        .font(.headline)
                    
                    VStack(spacing: 12) {
                        Button {
                            multipeerManager.userName = userName.isEmpty ? UIDevice.current.name : userName
                            multipeerManager.joinSession()
                        } label: {
                            HStack {
                                Image(systemName: "person.fill")
                                Text("Join as Listener")
                                Spacer()
                                Text("Request songs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .foregroundColor(.blue)
                        
                        // Become DJ button should be available only if not already connected to a DJ
                        if !multipeerManager.isConnected || multipeerManager.isDJ {
                            Button {
                                multipeerManager.userName = userName.isEmpty ? UIDevice.current.name : userName
                                multipeerManager.startHosting()
                            } label: {
                                HStack {
                                    Image(systemName: "music.mic")
                                    Text("Become DJ")
                                    Spacer()
                                    Text("Receive requests")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .foregroundColor(.green)
                        } else {
                            // When a DJ is present, show a read-only view explaining the role
                            HStack {
                                Image(systemName: "music.mic")
                                Text("DJ unavailable")
                                Spacer()
                                Text("View DJ queue")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                // Let listeners still view the DJ queue
                                multipeerManager.hasJoinedSession = true
                                multipeerManager.joinSession()
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Connection Status
                if multipeerManager.isConnected || multipeerManager.isDJ || multipeerManager.hasJoinedSession {
                    VStack(spacing: 8) {
                        HStack {
                            Circle()
                                .fill(multipeerManager.isConnected || multipeerManager.isDJ ? .green : .orange)
                                .frame(width: 8, height: 8)
                            
                            Text(getConnectionStatusText())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if multipeerManager.hasJoinedSession && !multipeerManager.isConnected && !multipeerManager.isDJ {
                            Text("Searching for DJ...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("Setup")
            .navigationBarHidden(true)
        }
    }
    
    /// Generates appropriate status text based on current connection state.
    /// 
    /// This helper method provides user-friendly status messages that reflect
    /// the current state of the multipeer connectivity session.
    /// 
    /// - Returns: Localized status string describing the current connection state
    private func getConnectionStatusText() -> String {
        if multipeerManager.isDJ {
            return "DJ Mode Active"
        } else if multipeerManager.isConnected {
            return "Connected to DJ"
        } else if multipeerManager.hasJoinedSession {
            return "Looking for DJ"
        } else {
            return "Ready to connect"
        }
    }
}

#Preview {
    ConnectionSetupView(multipeerManager: MultipeerManager())
}
