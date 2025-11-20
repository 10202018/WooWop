//
//  SongRequestView.swift
//  WooWop
//
//  Created by Theron Jones on 10/6/25.
//

import SwiftUI

/// View for sending song requests to connected DJs.
/// 
/// This view presents a detailed interface for users to review a song they've
/// identified and send it as a request to the currently connected DJ. It displays
/// the song's artwork, metadata, and connection status while providing controls
/// for submitting the request.
struct SongRequestView: View {
    /// The media item containing song details to be requested
    let mediaItem: MediaItem
    
    /// Manager handling multipeer connectivity and request transmission
    @ObservedObject var multipeerManager: MultipeerManager
    
    /// Controls the display of the success confirmation alert
    @State private var showingSuccessAlert = false
    
    /// Environment value for dismissing this view
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Song Artwork
                AsyncImage(url: mediaItem.artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
                .frame(width: 200, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Song Info
            VStack(spacing: 8) {
                Text(mediaItem.title ?? "Unknown Title")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(mediaItem.artist ?? "Unknown Artist")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Connection Status
            HStack {
                Circle()
                    .fill(multipeerManager.isConnected ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(multipeerManager.isConnected ? "Connected to DJ" : "Not connected to DJ")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Request Button
            Button {
                sendRequest()
            } label: {
                HStack {
                    Image(systemName: "music.note")
                        .font(.system(size: 24))
                    Text("Request This Song")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(multipeerManager.isConnected ? Color.blue : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!multipeerManager.isConnected)
            }
            .padding()
            .navigationTitle("Request Song")
            .navigationBarTitleDisplayMode(.inline)
            .background {
                ZStack {
                    // Full coverage background as view modifier
                    Color(red: 0.059, green: 0.047, blue: 0.161)
                        .ignoresSafeArea(.all)
                    
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.059, green: 0.047, blue: 0.161), // Deep midnight
                            Color(red: 0.102, green: 0.102, blue: 0.180)  // Dark purple-black
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea(.all)
                    
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
            }
        }
        .padding()
        .alert("Request Sent!", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your song request has been sent to the DJ!")
        }
    }
    
    /// Creates and sends a song request to connected peers.
    /// 
    /// This method constructs a SongRequest object with the current media item's
    /// information and the user's name, then transmits it via the multipeer manager.
    /// Shows a success alert upon completion.
    private func sendRequest() {
        let request = SongRequest(
            title: mediaItem.title ?? "Unknown Title",
            artist: mediaItem.artist ?? "Unknown Artist",
            requesterName: multipeerManager.userName,
            shazamID: mediaItem.shazamID
        )
        
        multipeerManager.sendSongRequest(request)
        showingSuccessAlert = true
    }
}

#Preview {
    NavigationView {
        SongRequestView(
            mediaItem: MediaItem(
                artworkURL: URL(string: "https://example.com/artwork.jpg")!,
                title: "Sample Song",
                artist: "Sample Artist",
                shazamID: "123456"
            ),
            multipeerManager: MultipeerManager()
        )
    }
}
